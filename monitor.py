import os
import sys
import requests  # Requires installation with 'pip install requests'

api_key = os.getenv('API_KEY')
api_url = os.getenv('API_URL')

if not api_key:
    print("Error: API Key must be set as environment variable 'API_KEY'.")
    sys.exit(1)

if not api_url:
    print("Error: API URL must be set as environment variable 'API_URL'.")
    sys.exit(1)

if not api_url.startswith('http://'):
    api_url = 'http://' + api_url.lstrip('https://')

if not api_url.endswith('/inspect'):
    api_url = api_url.rstrip('/') + '/inspect'

def health_check():
    try:
        response = requests.get(
            api_url,
            headers={'Authorization': f'Bearer {api_key}'}
        )

        if response.status_code == 200:
            data = response.json()
            cpu_used_percent = data['system']['cpu_used_percent']
            memory_used_percent = data['system']['memory_used_percent']

            if cpu_used_percent < 70 and memory_used_percent < 70:
                print("System is healthy.")
            else:
                print("Warning: High resource usage.")
                print("-----------------------------")

                if cpu_used_percent > 70:
                    print(f"    CPU: {cpu_used_percent}%")

                if memory_used_percent > 70:
                    print(f" Memory: {memory_used_percent}%")
        elif response.status_code == 401:
            print(f"Error: API_KEY is incorrect. HTTP Status Code: {response.status_code}")
        else:
            print(f"Error: Failed to get system info. HTTP Status Code: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Error: Request failed.\n{e}")
        sys.exit(1)

if __name__ == '__main__':
    health_check()
