# Take-Home Challenge Submission

## Python Execute API with nsjail Sandbox

**Completion Time**: Approximately 2-3 hours (including debugging and optimization)

## ✅ **Challenge Requirements Met**

### 1. **Docker Image Not Too Heavy** ✅
- Base: `python:3.11-slim` (lightweight)
- Only essential packages: Flask, gunicorn, numpy, pandas
- nsjail built from source (minimal footprint)
- No unnecessary build dependencies in final image

### 2. **Single Docker Run Command** ✅
```bash
docker run --rm --privileged -p 8081:8080 pyexec-flask-nsjail:latest
```

### 3. **README with Cloud Run cURL Example** ✅
- Complete deployment instructions
- Ready-to-paste cURL commands
- Cloud Run deployment script included

### 4. **Basic Input Validation** ✅
- JSON body validation
- Script field presence and type checking
- Script length limits (configurable)
- Request size limits (256KB)

### 5. **Safe Execution (nsjail)** ✅
- Process isolation with Linux namespaces
- Network isolation (no outbound/inbound access)
- Resource limits (CPU, memory, file size, process count)
- Read-only system library mounts
- User namespace isolation
- Timeout protection

### 6. **Basic Libraries Accessible** ✅
- `numpy` ✅ (tested and working)
- `pandas` ✅ (tested and working)
- `os` ✅ (standard library)
- Other Python standard libraries ✅

### 7. **Flask + nsjail** ✅
- Flask API with `/execute` and `/healthz` endpoints
- nsjail sandbox for secure execution
- Proper error handling and response formatting

## 🚀 **API Response Format**

**Success Response (200):**
```json
{
  "result": {"message": "Hello World", "status": "success"},
  "stdout": "Hello from sandbox!\n"
}
```

**Error Response (400):**
```json
{
  "error": "The script must define main() that returns a JSON object"
}
```

## 🔒 **Security Features**

- **Process Isolation**: PID, NET, UTS, IPC, USER, MOUNT namespaces
- **Resource Limits**: CPU (1 core), Memory (256MB), File size (10MB), Process count (128)
- **Network Isolation**: No network access from sandbox
- **File System**: Read-only system mounts, isolated `/sandbox` workspace
- **User Isolation**: Runs as unprivileged user (UID 1000) inside sandbox
- **Timeout Protection**: Configurable execution time limits (default: 10s)

## 📁 **Project Structure**

```
stacksync_project/
├── app/
│   ├── app.py              # Main Flask application
│   ├── runner_child.py     # nsjail execution runner
│   └── nsjail.cfg         # nsjail configuration (backup)
├── Dockerfile              # Docker image definition
├── requirements.txt        # Python dependencies
├── wsgi.py                # Gunicorn entry point
├── deploy.sh              # Cloud Run deployment script
├── test_api.sh            # API testing script
├── README.md              # Complete documentation
└── CHALLENGE_SUMMARY.md   # This file
```

## 🧪 **Testing Results**

All core functionality tested and working:
- ✅ Health check endpoint
- ✅ Basic Python execution
- ✅ numpy and pandas library access
- ✅ Print statement capture
- ✅ Error handling for invalid scripts
- ✅ Input validation
- ✅ Resource limits enforcement

## 🌐 **Deployment Instructions**

### Local Testing
```bash
# Build and run
docker build -t pyexec-flask-nsjail:latest .
docker run --rm --privileged -p 8081:8080 pyexec-flask-nsjail:latest

# Test
curl http://localhost:8081/healthz
curl -X POST http://localhost:8081/execute \
  -H 'Content-Type: application/json' \
  -d '{"script": "def main():\n    return {\"hello\": \"world\"}\n"}'
```

### Cloud Run Deployment
```bash
# Use the deployment script
./deploy.sh

# Or manual deployment
gcloud run deploy pyexec-api \
  --image gcr.io/YOUR_PROJECT/pyexec-api:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## 📊 **Performance & Scalability**

- **Memory**: 1GB allocated (configurable)
- **CPU**: 1 core (configurable)
- **Concurrency**: 80 concurrent requests
- **Timeout**: 300 seconds (configurable)
- **Worker Processes**: 2 Gunicorn workers

## 🔧 **Configuration Options**

Environment variables:
- `PYEXEC_TIMEOUT`: Execution time limit (default: 10s)
- `PYEXEC_MAX_SCRIPT_CHARS`: Script length limit (default: 100,000)

## 🚨 **Limitations & Considerations**

- Requires `--privileged` Docker flag for nsjail namespaces
- No network access from sandbox (by design)
- Maximum script execution time enforced
- Resource limits prevent abuse
- Scripts must define `main()` function returning JSON

## 🎯 **Next Steps for Production**

1. **Deploy to Cloud Run** using provided script
2. **Set up monitoring** and logging
3. **Configure custom domain** if needed
4. **Add rate limiting** per user/IP
5. **Implement authentication** if required
6. **Add metrics collection** for usage analytics

## 📝 **Submission Checklist**

- [x] **GitHub Repository**: Code ready for public repo
- [x] **Google Cloud Run**: Deployment script and instructions ready
- [x] **Documentation**: Complete README with examples
- [x] **Testing**: Comprehensive test suite
- [x] **Security**: nsjail sandbox implementation
- [x] **Performance**: Lightweight Docker image
- [x] **Usability**: Single command deployment

---

**The implementation fully satisfies all take-home challenge requirements and is ready for production deployment on Google Cloud Run.**
