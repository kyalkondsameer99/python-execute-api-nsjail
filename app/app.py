# app/app.py
import os
import json
import uuid
import tempfile
import shutil
import subprocess
from flask import Flask, request, jsonify

# Flask app
app = Flask(__name__)
# Basic request size guard (~256KB)
app.config["MAX_CONTENT_LENGTH"] = 256 * 1024

# Limits
DEFAULT_TIMEOUT = int(os.environ.get("PYEXEC_TIMEOUT", "10"))
MAX_SCRIPT_CHARS = int(os.environ.get("PYEXEC_MAX_SCRIPT_CHARS", "100000"))

@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200

@app.post("/execute")
def execute():
    # ---- Basic input validation ----
    if not request.is_json:
        return jsonify({"error": "Content-Type must be application/json"}), 400
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return jsonify({"error": "Invalid JSON body"}), 400
    script = payload.get("script")
    if not isinstance(script, str):
        return jsonify({"error": "Field 'script' must be a string"}), 400
    if len(script) > MAX_SCRIPT_CHARS:
        return jsonify({"error": f"Script too large (>{MAX_SCRIPT_CHARS} chars)"}), 413

    # ---- Prepare per-job workspace ----
    job_id = str(uuid.uuid4())
    host_job_dir = tempfile.mkdtemp(prefix=f"job_{job_id}_")
    try:
        user_py = os.path.join(host_job_dir, "user.py")
        with open(user_py, "w", encoding="utf-8") as f:
            f.write(script)

        # Copy child runner into the sandbox mount
        runner_src = os.path.join(os.path.dirname(__file__), "runner_child.py")
        runner_dst = os.path.join(host_job_dir, "runner_child.py")
        shutil.copyfile(runner_src, runner_dst)

        result_path = os.path.join(host_job_dir, ".result.json")

        # ---- nsjail command using command-line args instead of config file ----
        # -Mo: one-shot mode; command-line args for isolation
        ns_cmd = [
            "nsjail",
            "-Mo",  # one-shot mode
            "--user", "1000",
            "--group", "1000",
            "--time_limit", str(DEFAULT_TIMEOUT),
            "--max_cpus", "1",
            "--rlimit_as", "256",  # 256 MB
            "--rlimit_fsize", "10",  # 10 MB
            "--rlimit_nofile", "128",
            "--rlimit_nproc", "128",
            "--rlimit_cpu", "10",
            # Bind mount the job directory
            "--bindmount", f"{host_job_dir}:/sandbox",
            # Bind mount Python and system libraries (read-only)
            "--bindmount_ro", "/usr/local/bin:/usr/local/bin",
            "--bindmount_ro", "/usr/local/lib:/usr/local/lib",
            "--bindmount_ro", "/usr/lib:/usr/lib",
            "--bindmount_ro", "/lib:/lib",
            "--cwd", "/sandbox",
            "--",
            "/usr/local/bin/python",
            # keep -I (isolated mode) so user env/site-user is ignored,
            # but DO NOT use -S to allow system site-packages (numpy/pandas)
            "-I", "/sandbox/runner_child.py"
        ]

        # Run the jailed process
        completed = subprocess.run(
            ns_cmd,
            capture_output=True,
            text=True,
            timeout=DEFAULT_TIMEOUT + 2  # slight cushion for supervisor
        )

        # User's prints (runner itself doesn't print the result)
        user_stdout = completed.stdout or ""

        # Read result file
        result_obj = None
        if os.path.exists(result_path):
            try:
                with open(result_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                if isinstance(data, dict) and "result" in data and isinstance(data["result"], dict):
                    result_obj = data["result"]
            except Exception:
                result_obj = None

        if completed.returncode != 0 or result_obj is None:
            # Prefer structured error from runner (JSON on stderr)
            detail = None
            if completed.stderr:
                try:
                    detail = json.loads(completed.stderr).get("error")
                except Exception:
                    detail = completed.stderr.strip()
            if not detail and result_obj is None:
                detail = "The script must define main() that returns a JSON object"
            return jsonify({"error": detail or "Execution failed"}), 400

        # Success: only return `main()` result + captured stdout
        return jsonify({"result": result_obj, "stdout": user_stdout}), 200

    except subprocess.TimeoutExpired:
        return jsonify({"error": "Execution timed out"}), 408
    finally:
        try:
            shutil.rmtree(host_job_dir, ignore_errors=True)
        except Exception:
            pass

# For local dev (not used in production container which runs via gunicorn)
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
