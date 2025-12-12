# voting-app-ielm

**Voting app deployed with different docker containers using docker compose.**

This project demonstrates the deployment of a distributed multi-container application using Docker and Docker Compose. The application consists of five services connected via internal networks and uses persistent volumes for data storage.

## 🏗️ Architecture

The application uses a microservices architecture with the following data flow:

1.  **Vote (Python):** Front-end web app that lets users vote between two options (Cat vs Dog).
2.  **Redis:** In-memory data structure store, used as a temporary queue for votes.
3.  **Worker (.NET):** Background service that consumes votes from Redis and stores them in the database.
4.  **DB (PostgreSQL):** Persistent database where votes are stored.
5.  **Result (Node.js):** Front-end web app that shows the voting results in real-time.

### 🌐 Network Design

To ensure security and logical separation, the project uses two internal networks:

-   **front-tier:** Public-facing network. Connects `vote`, `result`, and `worker`.
-   **back-tier:** Internal network. Connects `redis`, `db`, `worker`, and `result`.

### 💾 Persistence

-   **Volume:** `pg-data` is mounted to the PostgreSQL container to ensure that voting data persists even if the container is removed or restarted.

---

## 🚀 Getting Started

### Prerequisites

-   Docker
-   Docker Compose

### Installation & Deployment

1.  **Clone the repository** (or download the files):

    ```bash
    git clone <repository-url>
    cd voting-app-ielm/app
    ```

2.  **Build and Start the containers:**

    ```bash
    docker compose up -d
    ```

3.  **Check running services:**
    ```bash
    docker compose ps
    ```

### Access the Application

-   **Voting App:** [http://localhost:5000](http://localhost:5000)
-   **Results App:** [http://localhost:5001](http://localhost:5001)

---

## 🛠️ Project Structure

```text
voting-app-ielm/
├── app/
│   ├── docker-compose.yml   # Orchestration configuration
│   ├── vote/                # Python Front-end
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── requirements.txt
│   ├── result/              # Node.js Front-end
│   │   ├── Dockerfile
│   │   ├── server.js
│   │   └── package.json
│   └── worker/              # .NET Background Processor
│       ├── Dockerfile
│       ├── Program.cs
│       └── Worker.csproj
├── deploy_final.sh          # Automation script to generate the solution
└── README.md
```

Entendido. Aquí tienes el contenido en crudo dentro de un bloque de código sin formato.

Copia el contenido dentro del recuadro y pégalo directamente en tu archivo README.md.
Plaintext

## 🐛 Troubleshooting & Fixes

**During development, several issues were addressed to ensure stability:**

1. Python Indentation: Fixed syntax errors in vote/app.py to prevent the container from crashing on startup.

2. Worker Race Condition: Implemented restart logic and dependency checks to handle cases where the Worker service started before the Database was ready to accept connections.

3. Network Isolation: Verified correct assignment of containers to front-tier and back-tier using docker network inspect.

## 🤖 Automation Script

**A script named deploy_final.sh is included. This script automatically:**

1. Generates the complete folder structure.

2. Creates all source code files with necessary fixes applied.

3. Generates the correct Dockerfile for each service.

4. Creates the docker-compose.yml.

**To use it:**

```bash
chmod +x deploy_final.sh
./deploy_final.sh
```

---

**Author:** _Issa El Mokadem_
