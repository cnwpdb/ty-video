import time
import json
import urllib.request
import urllib.parse
import os
import subprocess
import threading
import sys
import glob
import base64
import runpod

# Minimal ComfyUI Client
APP_URL = "http://127.0.0.1:8188"

def wait_for_service(url, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        try:
            urllib.request.urlopen(url, timeout=2)
            print("Service is UP")
            return True
        except Exception:
            time.sleep(1)
            if int(time.time() - start) % 10 == 0:
                print("Waiting for ComfyUI...")
    return False

def check_outputs(prompt_id):
    history_url = f"{APP_URL}/history/{prompt_id}"
    try:
        with urllib.request.urlopen(history_url) as response:
             history = json.loads(response.read())
        return history.get(prompt_id, {}).get('outputs', {})
    except Exception as e:
        print(f"Error checking outputs: {e}")
        return {}

def get_base64_file(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')

# Handler Function
def handler(event):
    input_payload = event["input"]
    
    # 1. Handle Input Images (Save to /comfyui/input)
    # Standard format: { "workflow": {}, "images": [{"name": "foo.png", "image": "b64..."}] }
    workflow = None
    
    if "images" in input_payload:
        for img in input_payload["images"]:
            try:
                name = img["name"]
                b64_data = img["image"]
                file_path = os.path.join("/comfyui/input", name)
                with open(file_path, "wb") as f:
                    f.write(base64.b64decode(b64_data))
                print(f"Saved input image: {name}")
            except Exception as e:
                print(f"Failed to save input image: {str(e)}")

    if "workflow" in input_payload:
        workflow = input_payload["workflow"]
    else:
        # Fallback: assume input IS the workflow
        workflow = input_payload

    # Send Prompt
    req_data = json.dumps({"prompt": workflow}).encode('utf-8')
    req = urllib.request.Request(f"{APP_URL}/prompt", data=req_data, headers={'Content-Type': 'application/json'})

    try:
        with urllib.request.urlopen(req) as response:
            resp_data = json.loads(response.read())
            prompt_id = resp_data['prompt_id']
            print(f"Workflow submitted. ID: {prompt_id}")
    except Exception as e:
        return {"error": f"ComfyUI Submit Failed: {str(e)}"}

    # Wait for Completion (Polling History)
    print("Watching for completion...")
    while True:
        history_url = f"{APP_URL}/history/{prompt_id}"
        try:
            with urllib.request.urlopen(history_url) as response:
                history_data = json.loads(response.read())
                if prompt_id in history_data:
                    print("Workflow Finished.")
                    break
        except Exception:
            pass
        time.sleep(1)

    # Collect Outputs
    final_output = {"status": "success", "images": [], "videos": []}

    # 1. Inspect ComfyUI History Output (Standard Nodes)
    outputs = history_data[prompt_id].get('outputs', {})

    # 2. Heuristic: Scan Output Folder for recent files (Robust fallback for VHS/Custom nodes)
    # We look for files created in the last 60 seconds to avoid returning old junk
    output_dir = "/comfyui/output"
    recent_limit = 300 # Look back 5 mins
    now = time.time()

    found_files = []

    # Extensions to capture
    extensions = ['*.mp4', '*.gif', '*.png', '*.jpg', '*.webp']
    for ext in extensions:
        for fpath in glob.glob(os.path.join(output_dir, ext)):
            if os.path.getmtime(fpath) > now - recent_limit:
                found_files.append(fpath)

    for fpath in found_files:
        filename = os.path.basename(fpath)
        b64_data = get_base64_file(fpath)

        if filename.endswith('.mp4') or filename.endswith('.gif'):
            final_output["videos"].append({
                "filename": filename,
                "type": "video" if filename.endswith('mp4') else "gif",
                "data": b64_data
            })
        else:
             final_output["images"].append({
                "filename": filename,
                "type": "image",
                "data": b64_data
            })

    if not final_output["images"] and not final_output["videos"]:
        final_output["status"] = "success_no_outputs"
        final_output["debug_history"] = outputs

    return final_output

# Start ComfyUI in Background
def start_comfy():
    print("Starting ComfyUI...")
    subprocess.Popen(["python", "main.py", "--listen", "--port", "8188"], cwd="/comfyui")
    return wait_for_service(APP_URL)

if __name__ == "__main__":
    if start_comfy():
        print("Starting RunPod Serverless Handler")
        runpod.serverless.start({"handler": handler})
    else:
        print("FATAL: ComfyUI failed to start within timeout. Exiting.")
        sys.exit(1)
