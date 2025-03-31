# Monitoring Script

This document outlines the design choices behind the monitoring script, written in Python.

## Why Python?
- **Easier dependency management:** To write a Bash script that achieves the same, the user must have tools like `curl`, `jq` and `bc` installed. This is harder to ensure and takes longer to install than the one dependency `requests` that we need to use the Python script.
- **HTTP response handling:** Manually parsing JSON from an HTTP response in Bash feels hacky and is prone to errors when met with unexpected responses. Python's `requests` library provides a more structured and reliable access to response data, making the code cleaner.

## Usage
### Creating and Activating a Virtual Environment
```bash
python -m venv venv
source venv/bin/activate
```

---

### Installing Dependencies
```bash
pip install requests
```

---

### Setting API Key and URL
```bash
export API_KEY=<THE_API_KEY>
export API_URL=<THE_API_URL>
```

#### Valid URL Examples:
```bash
export API_URL=somedomain.com
export API_URL=https://somedomain.com
export API_URL=http://somedomain.com/
```

---

### Running the Script
```bash
python monitor.py
```

---

### Cleanup
```bash
# Deactivate virtual environment
deactivate

# Remove virtual environment
rm -rf venv
```
