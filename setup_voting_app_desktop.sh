#!/usr/bin/env bash
set -e
echo "==> Creando proyecto voting-app con HUECOS para completar (Docker Desktop)"

PROJECT_ROOT="${PWD}/voting-app"

echo "==> Carpeta raíz: ${PROJECT_ROOT}"
mkdir -p "${PROJECT_ROOT}/vote" "${PROJECT_ROOT}/result" "${PROJECT_ROOT}/worker"

########################################
# 1. Servicio vote (Python)
########################################

echo "==> Creando servicio vote (Python) con código completo y Dockerfile incompleto"

cat > "${PROJECT_ROOT}/vote/app.py" << 'EOF'
from flask import Flask, render_template_string, request
import redis

app = Flask(__name__)

# El hostname 'redis' debe coincidir con el nombre del servicio en docker-compose.yml
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
if request.method == "POST":
    vote = request.form["vote"]
    redis_client.rpush("votes", vote)
return render_template_string(TEMPLATE)

if __name__ == "__main__":
app.run(host="0.0.0.0", port=80)
EOF

cat > "${PROJECT_ROOT}/vote/requirements.txt" << 'EOF'
flask
redis
EOF

cat > "${PROJECT_ROOT}/vote/Dockerfile" << 'EOF'
# TODO: Elegir una imagen base adecuada de Python
FROM <COMPLETAR_IMAGEN_PYTHON>

# TODO: Establecer el directorio de trabajo dentro del contenedor
WORKDIR <COMPLETAR_WORKDIR>

# TODO: Copiar el archivo de dependencias y ejecutarlas
COPY <COMPLETAR_REQUIREMENTS> .
RUN <COMPLETAR_INSTALACION_DEPENDENCIAS>

# TODO: Copiar el resto del código de la aplicación
COPY . .

# TODO: Exponer el puerto interno en el que escucha Flask
EXPOSE <COMPLETAR_PUERTO>

# TODO: Definir el comando de arranque del contenedor
CMD [<COMPLETAR_CMD>]

# PISTA:
# Imagen base típica: python:3.9
# WORKDIR recomendado: /app
# COPY requirements.txt .
# RUN pip3 install -r requirements.txt
# EXPOSE 80
# CMD ["python3", "app.py"]
EOF

########################################
# 2. Servicio result (Node.js)
########################################

echo "==> Creando servicio result (Node.js) con Dockerfile incompleto"

cat > "${PROJECT_ROOT}/result/server.js" << 'EOF'
const express = require("express");
const { Pool } = require("pg");

const app = express();
const port = 80;

// El hostname 'db' debe coincidir con el nombre del servicio de PostgreSQL en docker-compose.yml
const pool = new Pool({
host: "db",
user: "postgres",
password: "example",
database: "votes"
});

app.get("/", async (req, res) => {
const result = await pool.query("SELECT option, COUNT(*) AS count FROM votes GROUP BY option;");
let html = "<h1>Resultados</h1><ul>";
result.rows.forEach(r => {
html += `<li>${r.option}: ${r.count} votos</li>`;
});
html += "</ul>";
res.send(html);
});

app.listen(port, () => console.log(`Result service running on port ${port}`));
EOF

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

cat > "${PROJECT_ROOT}/result/Dockerfile" << 'EOF'
# TODO: Elegir una imagen base adecuada de Node.js
FROM <COMPLETAR_IMAGEN_NODE>

# TODO: Establecer el directorio de trabajo
WORKDIR <COMPLETAR_WORKDIR>

# TODO: Copiar package.json / package-lock.json y ejecutar npm install
COPY <COMPLETAR_PACKAGE_JSON> ./
RUN <COMPLETAR_NPM_INSTALL>

# TODO: Copiar el resto del código
COPY . .

# TODO: Exponer el puerto en el que escucha Express
EXPOSE <COMPLETAR_PUERTO>

# TODO: Definir el comando para arrancar la aplicación
CMD [<COMPLETAR_CMD>]

# PISTA:
# Imagen base típica: node:18
# WORKDIR recomendado: /app
# COPY package*.json ./
# RUN npm install
# EXPOSE 80
# CMD ["node", "server.js"]
EOF

########################################
# 3. Servicio worker (.NET 8)
########################################

echo "==> Creando servicio worker (.NET 8) con Dockerfile incompleto"

cat > "${PROJECT_ROOT}/worker/Program.cs" << 'EOF'
using StackExchange.Redis;
using Npgsql;

var redis = ConnectionMultiplexer.Connect("redis:6379");
var dbRedis = redis.GetDatabase();

// La cadena de conexión usa el servicio 'db' definido en docker-compose.yml
var connString = "Host=db;Username=postgres;Password=example;Database=votes";

Console.WriteLine("Worker en ejecución. Esperando votos...");

// Crear tabla si no existe
using (var initConn = new NpgsqlConnection(connString))
{
initConn.Open();
using var initCmd = new NpgsqlCommand(
    "CREATE TABLE IF NOT EXISTS votes (id SERIAL PRIMARY KEY, option VARCHAR(50));",
    initConn
);
initCmd.ExecuteNonQuery();
}

while (true)
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

Thread.Sleep(500);
}
EOF

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

cat > "${PROJECT_ROOT}/worker/Dockerfile" << 'EOF'
# TODO: Elegir una imagen base adecuada de .NET SDK
FROM <COMPLETAR_IMAGEN_DOTNET>

# TODO: Establecer el directorio de trabajo
WORKDIR <COMPLETAR_WORKDIR>

# TODO: Copiar los archivos del proyecto
COPY . .

# TODO: Restaurar paquetes y compilar en modo Release
RUN <COMPLETAR_DOTNET_RESTORE>
RUN <COMPLETAR_DOTNET_BUILD>

# TODO: Definir el comando de arranque
CMD [<COMPLETAR_CMD>]

# PISTA:
# Imagen base típica: mcr.microsoft.com/dotnet/sdk:8.0
# WORKDIR recomendado: /app
# RUN dotnet restore
# RUN dotnet build -c Release
# CMD ["dotnet", "run", "-c", "Release"]
EOF

########################################
# 4. docker-compose.yml con huecos
########################################

echo "==> Creando docker-compose.yml con huecos para completar"

cat > "${PROJECT_ROOT}/docker-compose.yml" << 'EOF'
services:

vote:
# TODO: Indicar que la imagen se construya a partir del Dockerfile de vote
build: <COMPLETAR_RUTA_BUILD_VOTE>
# TODO: Mapear el puerto del host al puerto interno del contenedor
ports:
    - "<COMPLETAR_PUERTO_HOST_VOTE>:<COMPLETAR_PUERTO_CONTENEDOR_VOTE>"
# TODO: Conectar este servicio a las redes adecuadas
networks:
    - <COMPLETAR_RED_FRONT>
    - <COMPLETAR_RED_BACK>
# TODO: Indicar dependencia de redis para que arranque después
depends_on:
    - <COMPLETAR_SERVICIO_REDIS>

result:
# TODO: Indicar build desde la carpeta result
build: <COMPLETAR_RUTA_BUILD_RESULT>
ports:
    - "<COMPLETAR_PUERTO_HOST_RESULT>:<COMPLETAR_PUERTO_CONTENEDOR_RESULT>"
networks:
    - <COMPLETAR_RED_FRONT>
    - <COMPLETAR_RED_BACK>
# TODO: Este servicio depende de la base de datos
depends_on:
    - <COMPLETAR_SERVICIO_DB>

worker:
# TODO: Indicar build desde la carpeta worker
build: <COMPLETAR_RUTA_BUILD_WORKER>
networks:
    - <COMPLETAR_RED_FRONT>
    - <COMPLETAR_RED_BACK>
depends_on:
    - <COMPLETAR_SERVICIO_REDIS>
    - <COMPLETAR_SERVICIO_DB>

redis:
image: redis:7
networks:
    - <COMPLETAR_RED_BACK>

db:
image: postgres:15
environment:
    # TODO: Variables de entorno mínimas para Postgres
    POSTGRES_PASSWORD: <COMPLETAR_PASSWORD_DB>
    POSTGRES_DB: <COMPLETAR_NOMBRE_BD>
volumes:
    - pg-data:/var/lib/postgresql/data
networks:
    - <COMPLETAR_RED_BACK>

networks:
# TODO: Definir las redes necesarias (por ejemplo front-tier y back-tier)
<COMPLETAR_RED_FRONT>:
<COMPLETAR_RED_BACK>:

volumes:
pg-data:
EOF

echo
echo "============================================================"
echo "Proyecto con huecos creado en: ${PROJECT_ROOT}"
echo
echo "Ahora el alumnado debe:"
echo "  1) Completar los Dockerfile (reemplazar <COMPLETAR_...>)."
echo "  2) Completar docker-compose.yml:"
echo "       - rutas de build"
echo "       - mapeos de puertos (5000, 5001, etc.)"
echo "       - nombres de servicios (redis, db)"
echo "       - nombres de redes (por ejemplo front-tier, back-tier)"
echo "  3) Ejecutar: docker compose up -d"
echo
echo "Recuerda que esto está pensado para Docker Desktop en ejecución."
echo "============================================================"
