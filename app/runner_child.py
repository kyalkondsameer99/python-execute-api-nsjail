"""
Runs INSIDE nsjail.
Loads /sandbox/user.py, ensures main() exists and returns a JSON object (dict).
Writes {"result": <dict>} to /sandbox/.result.json.
Prints nothing except the user's own prints from their script.
"""
import importlib.util, os, sys, json, traceback

SANDBOX_DIR = "/sandbox"
USER_FILE = os.path.join(SANDBOX_DIR, "user.py")
RESULT_FILE = os.path.join(SANDBOX_DIR, ".result.json")

def _load_user_module(path: str):
    # Restrict imports to the sandbox directory and system site-packages
    sys.path = [SANDBOX_DIR] + [p for p in sys.path if "site-packages" in p or p.startswith("/usr")]
    spec = importlib.util.spec_from_file_location("user", path)
    if spec is None or spec.loader is None:
        raise ImportError("Could not load user module")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def write_result(obj):
    with open(RESULT_FILE, "w", encoding="utf-8") as f:
        json.dump({"result": obj}, f, ensure_ascii=False)

def main():
    if not os.path.exists(USER_FILE):
        raise FileNotFoundError("user.py not found")
    mod = _load_user_module(USER_FILE)

    if not hasattr(mod, "main") or not callable(getattr(mod, "main")):
        raise TypeError("The script must define a callable main()")

    value = mod.main()

    if not isinstance(value, dict):
        raise TypeError("main() must return a JSON object (Python dict)")

    # Validate JSON-serializable now
    json.dumps(value)
    write_result(value)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        sys.stderr.write(json.dumps({"error": str(e), "trace": traceback.format_exc()}))
        sys.stderr.write("\n")
        sys.exit(1)
