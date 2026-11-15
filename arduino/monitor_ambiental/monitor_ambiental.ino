#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

// Cambia a 1 cuando tengas la resistencia y el DHT11 conectado.
#define USAR_DHT11 0
#if USAR_DHT11
  #include <DHT.h>  // Instalar "DHT sensor library" de Adafruit y su dependencia
  #define DHT_PIN 4
  DHT dht(DHT_PIN, DHT11);
#endif

// CONFIGURACIÓN: sustituye estos valores antes de cargar el sketch.
const char* WIFI_NOMBRE = "";
const char* WIFI_CLAVE = "";
const char* FUNCION_URL = "https://flxtndpcvwxmpludoehb.supabase.co/functions/v1/registrar-lectura";
const char* DEVICE_TOKEN = "";
const char* DISPOSITIVO = "esp32-01";

// Solo para la PRUEBA INICIAL: HTTPS sin validación de certificado.
// Para uso real, configura un certificado raíz confiable con setCACert().
const bool MODO_PRUEBA_TLS = true;

unsigned long ultimaLectura = 0;
const unsigned long INTERVALO_MS = 15000;


const char* REDES_ABIERTAS_PERMITIDAS[] = {
  "WiFi_Laboratorio",
  "WiFi_Invitados"
};

bool esperarConexion(unsigned long tiempoMs) {
  unsigned long inicio = millis();

  while (WiFi.status() != WL_CONNECTED &&
         millis() - inicio < tiempoMs) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  return WiFi.status() == WL_CONNECTED;
}

void conectarWifi() {
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  WiFi.mode(WIFI_STA);

  // Cancelar cualquier intento anterior
  WiFi.disconnect(false, false);
  delay(500);

  Serial.println("Conectando a Wi-Fi...");
  Serial.println(WIFI_NOMBRE);

  WiFi.begin(WIFI_NOMBRE, WIFI_CLAVE);

  // Esperar hasta 20 segundos
  unsigned long inicio = millis();

  while (WiFi.status() != WL_CONNECTED &&
         millis() - inicio < 20000) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("CONEXION WIFI EXITOSA");
    Serial.print("Direccion IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("Senal: ");
    Serial.println(WiFi.RSSI());
  } else {
    Serial.println("ERROR: No se pudo conectar al Wi-Fi");

    // Cerrar correctamente el intento fallido
    WiFi.disconnect(false, false);
  }
}

void enviarLectura(float temperatura, float humedad, bool simulada) {
  conectarWifi();
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Lectura no enviada: sin Wi-Fi");
    return;
  }
  WiFiClientSecure cliente;
  if (MODO_PRUEBA_TLS) {
    cliente.setInsecure(); // NO usar en produccion.
  } else {
    Serial.println("Falta configurar certificado CA para TLS verificado");
    return;
  }
  HTTPClient http;
  if (!http.begin(cliente, FUNCION_URL)) {
    Serial.println("No se pudo iniciar HTTP");
    return;
  }
  http.setTimeout(12000);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-device-token", DEVICE_TOKEN);
  String cuerpo = "{\"dispositivo\":\"" + String(DISPOSITIVO) +
                  "\",\"temperatura\":" + String(temperatura, 2) +
                  ",\"humedad\":" + String(humedad, 2) +
                  ",\"simulada\":" + String(simulada ? "true" : "false") + "}";
  int estado = http.POST(cuerpo);
  Serial.printf("HTTP %d | %s\n", estado, cuerpo.c_str());
  if (estado > 0) Serial.println(http.getString());
  else Serial.println(http.errorToString(estado));
  http.end();
}

void setup() {
  Serial.begin(115200);
  delay(600);
  #if USAR_DHT11
    dht.begin();
  #else
    randomSeed(esp_random());
  #endif
  conectarWifi();
  ultimaLectura = millis() - INTERVALO_MS;
}

void loop() {
  if (millis() - ultimaLectura < INTERVALO_MS) return;
  ultimaLectura = millis();
  float temperatura, humedad;
  #if USAR_DHT11
    temperatura = dht.readTemperature();
    humedad = dht.readHumidity();
    if (isnan(temperatura) || isnan(humedad)) {
      Serial.println("Error de lectura del DHT11");
      return;
    }
  #else
    temperatura = random(220, 311) / 10.0; // 22.0 a 31.0 grados C (SIMULADO)
    humedad = random(400, 751) / 10.0;     // 40.0 a 75.0 % (SIMULADO)
  #endif
  enviarLectura(temperatura, humedad, !USAR_DHT11);
}
