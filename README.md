# Python Execute API with nsjail Sandbox

A secure Python code execution service built with Flask and nsjail for safe execution of user-provided Python scripts in an isolated environment.

**GitHub Repository**: [https://github.com/kyalkondsameer99/python-execute-api-nsjail](https://github.com/kyalkondsameer99/python-execute-api-nsjail)

## Features

- **Secure Execution**: Uses nsjail for process isolation and sandboxing
- **Resource Limits**: CPU, memory, and file size restrictions
- **Library Access**: numpy, pandas, and other Python libraries available
- **Input Validation**: Script length and format validation
- **Error Handling**: Proper error responses for invalid scripts
- **Docker Ready**: Single command deployment

## API Endpoints

### Health Check
```bash
GET /healthz
```
Returns service status.

### Execute Python Script
```bash
POST /execute
Content-Type: application/json

{
  "script": "def main():\n    return {\"message\": \"Hello World\"}\n"
}
```

**Response Format:**
```json
{
  "result": {"message": "Hello World"},
  "stdout": "any print statements from the script"
}
```

## Local Development

### Prerequisites
- Docker
- Port 8081 available (or change the mapping)

### Run Locally
```bash
# Build the image
docker build -t pyexec-flask-nsjail:latest .

# Run with privileges (required for nsjail)
docker run --rm --privileged -p 8081:8080 pyexec-flask-nsjail:latest

# Test the API
curl http://localhost:8081/healthz
curl -X POST http://localhost:8081/execute \
  -H 'Content-Type: application/json' \
  -d '{"script": "def main():\n    return {\"hello\": \"world\"}\n"}'
```

## Google Cloud Run Deployment

### 1. Build and Push to Google Container Registry
```bash
# Set your project ID
export PROJECT_ID=your-project-id

# Build and tag
docker build -t gcr.io/$PROJECT_ID/pyexec-api:latest .

# Push to registry
docker push gcr.io/$PROJECT_ID/pyexec-api:latest
```

### 2. Deploy to Cloud Run
```bash
gcloud run deploy pyexec-api \
  --image gcr.io/$PROJECT_ID/pyexec-api:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 300 \
  --concurrency 80
```

### 3. Test the Deployed Service
```bash
# Replace with your actual Cloud Run URL
curl -X POST https://pyexec-api-xxxxx-uc.a.run.app/execute \
  -H 'Content-Type: application/json' \
  -d '{"script": "def main():\n    import numpy as np\n    arr = np.array([1,2,3])\n    return {\"sum\": int(np.sum(arr))}\n"}'
```

## Security Features

- **Process Isolation**: Linux namespaces (PID, NET, UTS, IPC, USER, MOUNT)
- **Resource Limits**: CPU (1 core), Memory (256MB), File size (10MB), Process count (128)
- **Network Isolation**: No network access from sandbox
- **File System**: Read-only system mounts, isolated `/sandbox` workspace
- **User Isolation**: Runs as unprivileged user (UID 1000) inside sandbox
- **Timeout Protection**: Configurable execution time limits (default: 10s)

## Architecture

```
User Request → Flask API → nsjail Sandbox → Python Execution → Result
                ↓              ↓              ↓              ↓
            Validation    Process Isolation  Script Run   JSON Response
```

## Example Scripts

### Basic Example
```python
def main():
    return {"message": "Hello from sandbox!", "status": "success"}
```

### With Libraries
```python
def main():
    import numpy as np
    import pandas as pd
    
    data = np.random.randn(100)
    df = pd.DataFrame({"values": data})
    
    return {
        "mean": float(np.mean(data)),
        "std": float(np.std(data)),
        "shape": list(df.shape)
    }
```

### Error Handling
```python
def main():
    # This will return an error - no main() function
    return {"error": "This script is missing main()"}
```

## Configuration

Environment variables:
- `PYEXEC_TIMEOUT`: Maximum execution time in seconds (default: 10)
- `PYEXEC_MAX_SCRIPT_CHARS`: Maximum script length (default: 100,000)

## Limitations

- Scripts must define a `main()` function
- `main()` must return a JSON-serializable object
- No network access from sandbox
- Limited system resources
- Maximum execution time enforced

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure Docker runs with `--privileged` flag
2. **Port Already in Use**: Change the port mapping (e.g., `-p 8082:8080`)
3. **nsjail Errors**: Check that the container has proper privileges

### Debug Mode

To see detailed nsjail logs, modify the app to capture stderr:
```python
# In app.py, change capture_output=True to capture_output=True, stderr=subprocess.PIPE
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions, please open a GitHub issue or contact the development team.
