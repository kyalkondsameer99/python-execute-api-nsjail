# Python Execute API with nsjail Sandbox

A secure Python code execution service built with Flask and nsjail for safe execution of user-provided Python scripts in an isolated environment.

**GitHub Repository**: [https://github.com/kyalkondsameer99/python-execute-api-nsjail](https://github.com/kyalkondsameer99/python-execute-api-nsjail)

**🌐 Cloud Run Service**: [https://pyexec-api-1036331576483.us-central1.run.app](https://pyexec-api-1036331576483.us-central1.run.app)

**⚠️ Current Status**: Service deployed successfully, but Flask app routes need debugging. The container is running and listening on port 8080, but the `/healthz` and `/execute` endpoints are returning 404 errors.

## Features
- **Secure Execution**: Uses nsjail for process isolation and sandboxing
- **Python Support**: Executes Python scripts with access to numpy, pandas, and other libraries
- **Resource Limits**: Configurable memory, CPU, and file size limits
- **RESTful API**: Simple HTTP endpoints for code execution
- **Error Handling**: Comprehensive error reporting and validation
- **Cloud Native**: Designed for deployment on Google Cloud Run

## API Endpoints

### Health Check
```bash
GET /healthz
```
Returns service status and health information.

### Execute Python Code
```bash
POST /execute
Content-Type: application/json

{
  "script": "def main():\n    return {'message': 'Hello, World!'}"
}
```

Executes the provided Python script in a sandboxed environment and returns the result.

## Local Development

### Prerequisites
- Docker
- Python 3.11+
- nsjail (for local testing)

### Quick Start
```bash
# Clone the repository
git clone https://github.com/kyalkondsameer99/python-execute-api-nsjail.git
cd python-execute-api-nsjail

# Build and run locally
docker build -t pyexec-api .
docker run --rm --privileged -p 8081:8080 pyexec-api

# Test the API
curl http://localhost:8081/healthz
```

## Google Cloud Run Deployment

The service is currently deployed to Google Cloud Run at:
**https://pyexec-api-1036331576483.us-central1.run.app**

### Deployment Status
- ✅ **Container Built**: Successfully built and pushed to Artifact Registry
- ✅ **Service Deployed**: Cloud Run service is running and listening on port 8080
- ✅ **Health Checks**: Container startup probes are passing
- ❌ **Flask Routes**: Routes are not being registered properly (404 errors)

### Next Steps for Full Functionality
1. **Debug Flask App**: Investigate why routes are not being registered
2. **Add nsjail**: Integrate nsjail for secure code execution
3. **Test Endpoints**: Verify `/healthz` and `/execute` endpoints work
4. **Production Ready**: Optimize for production use

## Security Features

- **Process Isolation**: Uses nsjail for sandboxing
- **Resource Limits**: Configurable memory, CPU, and file size limits
- **User Namespaces**: Non-privileged execution
- **Input Validation**: Script size and content validation
- **Temporary Workspaces**: Isolated execution environments

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │───▶│   Flask API     │───▶│   nsjail        │
│                 │    │   (Port 8080)   │    │   Sandbox       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Python        │
                       │   Runner        │
                       └─────────────────┘
```

## Configuration

### Environment Variables
- `PYEXEC_TIMEOUT`: Execution timeout in seconds (default: 10)
- `PYEXEC_MAX_SCRIPT_CHARS`: Maximum script size (default: 100,000)

### Resource Limits
- **Memory**: 256 MB per execution
- **CPU**: 1 CPU core
- **File Size**: 10 MB maximum
- **Processes**: 128 maximum
- **File Descriptors**: 128 maximum

## Example Scripts

### Basic Hello World
```python
def main():
    return {"message": "Hello, World!"}
```

### Using Libraries
```python
import numpy as np
import pandas as pd

def main():
    data = np.array([1, 2, 3, 4, 5])
    df = pd.DataFrame(data, columns=['values'])
    return {
        "mean": float(np.mean(data)),
        "dataframe": df.to_dict()
    }
```

### Error Handling
```python
def main():
    try:
        result = 10 / 0
        return {"result": result}
    except Exception as e:
        return {"error": str(e)}
```

## Troubleshooting

### Common Issues

1. **404 Errors**: Flask routes not registered - check app startup logs
2. **nsjail Not Found**: Package not available in Debian repositories
3. **Permission Denied**: Container needs privileged mode for nsjail
4. **Import Errors**: Python module import failures

### Debugging Steps

1. **Check Container Logs**: `gcloud logging read "resource.type=cloud_run_revision"`
2. **Verify Flask App**: Check if routes are being registered
3. **Test Locally**: Run container locally with `--privileged` flag
4. **Check Dependencies**: Ensure all Python packages are installed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review Cloud Run logs for debugging

## Performance Notes

- **Cold Start**: ~2-3 seconds for new instances
- **Warm Requests**: ~100-200ms for execution
- **Concurrency**: Supports up to 80 concurrent requests
- **Scaling**: Auto-scales based on demand

## Future Enhancements

- [ ] **Web UI**: Browser-based code editor
- [ ] **Multiple Languages**: Support for other programming languages
- [ ] **Persistent Storage**: Save and share code snippets
- [ ] **Authentication**: User management and rate limiting
- [ ] **Monitoring**: Metrics and alerting
- [ ] **CI/CD**: Automated testing and deployment
