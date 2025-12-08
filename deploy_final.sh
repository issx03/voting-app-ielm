#!/usr/bin/env bash
set -e
echo "==> Generando SOLUCIÓN COMPLETA de voting-app (TODOS completados)..."

# Nombre de la carpeta destino
PROJECT_ROOT="${PWD}/app"

echo "==> Carpeta raíz: ${PROJECT_ROOT}"
mkdir -p "${PROJECT_ROOT}/vote" "${PROJECT_ROOT}/result" "${PROJECT_ROOT}/worker"

########################################
# 1. Servicio VOTE (Python) - CORREGIDO
########################################
echo "==> Generando vote/app.py (Con indentación arreglada)"
cat > "${PROJECT_ROOT}/vote/app.py" << 'EOF'
from flask import Flask, render_template_string, request
import redis

app = Flask(__name__)

# El hostname 'redis' coincide con el nombre del servicio en docker-compose
redis_client = redis.Redis(host='redis', port=6379)

TEMPLATE = """
<h1>Vota tu favorito</h1>
<form method="POST">
<button name="vote" value="gato">Gato</button>
<button name="vote" value="perro">Perro</button>
</form>
"""

@app.route("/", methods=["GET", "POST"])
def index():
# Corregido indentación
    if request.method == "POST":
        vote = request.form["vote"]
        redis_client.rpush("votes", vote)
    return render_template_string(TEMPLATE)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
EOF

echo "==> Generando vote/requirements.txt"
cat > "${PROJECT_ROOT}/vote/requirements.txt" << 'EOF'
flask
redis
EOF

echo "==> Generando vote/Dockerfile (Completado)"
cat > "${PROJECT_ROOT}/vote/Dockerfile" << 'EOF'
# Elegida imagen oficial de Python
FROM python:3.9
# Se establece el directorio de trabajo
WORKDIR /app
# Se copia el archivo requirements.txt
COPY requirements.txt .
# Se instalan las dependencias
RUN pip install -r requirements.txt
# Se copia el resto del código
COPY . .
# Se expone el puerto 80
EXPOSE 80
# Se ejecuta el script app.py
CMD ["python3", "app.py"]
EOF

########################################
# 2. Servicio RESULT (Node.js)
########################################
echo "==> Generando result/server.js"
cat > "${PROJECT_ROOT}/result/server.js" << 'EOF'
const express = require("express");
const { Pool } = require("pg");

const app = express();
const port = 80;

const pool = new Pool({
    host: "db",
    user: "postgres",
    password: "example",
    database: "votes"
});

app.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT option, COUNT(*) AS count FROM votes GROUP BY option;");
        let html = "<h1>Resultados</h1><ul>";
        result.rows.forEach(r => {
        html += `<li>${r.option}: ${r.count} votos</li>`;
        });
        html += "</ul>";
        res.send(html);
    } catch (err) {
        res.send("<h1>Esperando a la base de datos...</h1>");
    }
});

app.listen(port, () => console.log(`Result service running on port ${port}`));
EOF

echo "==> Generando result/package.json"
cat > "${PROJECT_ROOT}/result/package.json" << 'EOF'
{
    "name": "result",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {
        "express": "^4.18.2",
        "pg": "^8.10.0"
    }
}
EOF

echo "==> Generando result/Dockerfile (Completado)"
cat > "${PROJECT_ROOT}/result/Dockerfile" << 'EOF'
# Elegida imagen oficial de Node.js
FROM node:18
# Se establece el directorio de trabajo
WORKDIR /app
# Se copia el archivo package.json
COPY package*.json ./
# Se instalan las dependencias
RUN npm install
COPY . .
# Se expone el puerto 80
EXPOSE 80
# Se ejecuta el script server.js
CMD ["node", "server.js"]
EOF

########################################
# 3. Servicio WORKER (.NET)
########################################
echo "==> Generando worker/Program.cs"
cat > "${PROJECT_ROOT}/worker/Program.cs" << 'EOF'
using StackExchange.Redis;
using Npgsql;

// Esperar un poco a que los servicios arranquen (parche simple para esperar a la base de datos)
Thread.Sleep(3000);

var redis = ConnectionMultiplexer.Connect("redis:6379");
var dbRedis = redis.GetDatabase();

// Usamos password 'example' para coincidir con el docker-compose
var connString = "Host=db;Username=postgres;Password=example;Database=votes";

Console.WriteLine("Worker en ejecución. Esperando votos...");

try 
{
    using (var initConn = new NpgsqlConnection(connString))
    {
        initConn.Open();
        using var initCmd = new NpgsqlCommand(
            "CREATE TABLE IF NOT EXISTS votes (id SERIAL PRIMARY KEY, option VARCHAR(50));",
            initConn
        );
        initCmd.ExecuteNonQuery();
    }
}
catch (Exception ex)
{
    Console.WriteLine($"Error inicializando DB: {ex.Message}");
}

while (true)
{
    try 
    {
        var value = dbRedis.ListLeftPop("votes");
        if (!value.IsNullOrEmpty)
        {
            Console.WriteLine($"Procesando voto: {value}");
            using var conn = new NpgsqlConnection(connString);
            conn.Open();
            using var cmd = new NpgsqlCommand("INSERT INTO votes (option) VALUES (@v);", conn);
            cmd.Parameters.AddWithValue("v", value.ToString());
            cmd.ExecuteNonQuery();
        }
    }
    catch (Exception e)
    {
        Console.WriteLine($"Error procesando: {e.Message}");
    }
    Thread.Sleep(500);
}
EOF

echo "==> Generando worker/Worker.csproj"
cat > "${PROJECT_ROOT}/worker/Worker.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>net8.0</TargetFramework>
        <Nullable>enable</Nullable>
        <ImplicitUsings>enable</ImplicitUsings>
    </PropertyGroup>
    <ItemGroup>
        <PackageReference Include="StackExchange.Redis" Version="2.6.122" />
        <PackageReference Include="Npgsql" Version="7.0.6" />
    </ItemGroup>
</Project>
EOF

echo "==> Generando worker/Dockerfile (Completado)"
cat > "${PROJECT_ROOT}/worker/Dockerfile" << 'EOF'
# Elegida imagen oficial de .NET
FROM mcr.microsoft.com/dotnet/sdk:8.0
# Se establece el directorio de trabajo
WORKDIR /app
# Se copia el resto del código
COPY . .
# Se restauran las dependencias
RUN dotnet restore
# Se compila el proyecto
RUN dotnet build -c Release
# Se ejecuta el script Worker.cs
CMD ["dotnet", "run", "-c", "Release"]
EOF

########################################
# 4. docker-compose.yml
########################################
echo "==> Generando docker-compose.yml (Completado)"
cat > "${PROJECT_ROOT}/docker-compose.yml" << 'EOF'
services:
    vote:
        # Se construye el servicio
        build: ./vote
        # Se mapea el puerto 5000 al puerto 80
        ports:
        - "5000:80"
        # Se conecta a las redes front-tier y back-tier
        networks:
        - front-tier
        - back-tier
        # Se depende de redis
        depends_on:
        - redis

    result:
        # Se construye el servicio
        build: ./result
        # Se mapea el puerto 5001 al puerto 80
        ports:
        - "5001:80"
        # Se conecta a las redes front-tier y back-tier
        networks:
        - front-tier
        - back-tier
        # Se depende de db
        depends_on:
        - db

    worker:
        # Se construye el servicio
        build: ./worker
        # Se conecta a las redes front-tier y back-tier
        networks:
        - front-tier
        - back-tier
        # Se depende de redis y db
        depends_on:
        - redis
        - db

    redis:
        # Se utiliza la imagen oficial de Redis
        image: redis:7
        # Se conecta a la red back-tier
        networks:
        - back-tier

    db:
        # Se utiliza la imagen oficial de PostgreSQL
        image: postgres:15
        environment:
            POSTGRES_PASSWORD: issa1234
            POSTGRES_DB: votes
        volumes:
        - pg-data:/var/lib/postgresql/data
        networks:
        - back-tier

networks:
    # Se definen las redes front-tier y back-tier
    front-tier:
    back-tier:

volumes:
    # Se definen los volúmenes pg-data
    pg-data:
EOF

echo
echo "============================================================"
echo " SOLUCIÓN GENERADA EN: ${PROJECT_ROOT}"
echo "============================================================"
echo "Pasos para desplegar:"
echo "  1) cd ${PROJECT_ROOT}"
echo "  2) docker compose up -d"
echo
echo "Nota: Se ha añadido un pequeño 'sleep' en el worker y corregido"
echo "la indentación de Python automáticamente."
echo "============================================================"