# vdb_secure_token - 1.0.8

SDK de VIRIDIAN Digital Banking denominado VDB Secure Token, que sirve, en conjunto con las interfaces del Back End, para:
- Registrar un dispositivo como 2do Factor de Autenticación o Token 
- Obtener Códigos de Autorización (OTP) que servirán para autorizar o no una transacción.

Para el funcionamiento de este SDK es necesario que la aplicación tenga implementada las librerías 
Firebase Cloud Messaging, para Android y iOS o Huawei Push Kit para Harmony OS.

## Instalación

1. En el archivo `pubspec.yaml` de la aplicación cliente agregar las siguientes dependencias:
``` yaml
  loggy: ^2.0.3
  vdb_secure_token:
    git: 
      url: ssh://git@git.viridian.ltd:2224/viridian/bsol/vdb_secure_token.git
      ref: 1.0.0
```

> La version del package vdb_secure_token a instalar debe ser consultada con VIRIDIAN.

> El o los desarroladores deben enviar su llave SSH pública a VIRIDIAN para usar el package vdb_secure_token

2. Luego instalar las dependencias:

```
    flutter pub get
```

## Configuración

### Configuración Android

1. Editar el archivo `AndroidManifest.xml` para agregar permisos para acceder a la ubicación:

``` xml
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

2. Editar el archivo `app/build.gradle` , cambiar el minSdkVersion a 21

```
android {
.
.
  defaultConfig {
    .
    .
    minSdkVersion 21
    .
    .
  } 
}
```

### Configuración iOS

1. Editar el archivo `Info.plist` para agregar permisos para acceder a la ubicación:

```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app needs access to location when open.</string>
```

### Configuración Huawei

### Configuración del SDK en la aplicación cliente

Antes de la llamada al widget inicial con `runApp`, se debe configurar el SDK:

1. Primero se configura el logger del SDK:

``` dart
    Loggy.initLoggy(
        logPrinter: const PrettyPrinter(showColors: true),
        logOptions: const LogOptions(
            LogLevel.debug,
            stackTraceLevel: LogLevel.error,
        ),
    );
```

2. Luego se configura las credenciales del SDK:

``` dart
    ConfigService.initVector = "XXX";
    ConfigService.key = "xxx";

    runApp(const MyApp());
```

> Ambos valores serán distintos para cada entorno, se entregaran los valores por correo electrónico.


## Obtención del Secure Payload

El Secure Payload contiene toda la información recopilada del dispositivo, esta información permite identificar y validar la autenticidad del dispositivo para que pueda recibir Códigos de Autorización.

Para obtener el Secure Payload, se debe usar el método `getSecurePayload` de la clase `DeviceService`:

  ``` dart
    String securePayload = await DeviceService.getSecurePayload(
        platform: PlatformsEnum.fcm,
        pushToken: "123qwe456",
        locationMandatory: true,
        locationTimeLimit: Duration(seconds: 30),
    );

    // handle securePayload var
  ```

Se deben enviar los siguientes parametros:

- **platform:** Plataforma de recepción de notificación push implementada de acuerdo al sistema operativo, los posibles valores son:
    fcm: Firebase Cloud Messaging
    hpk: Huawei Push Kit

- **pushToken:** Token que identifica al dispositivo en la plataforma de mensajería usada de acuerdo al sistema operativo: Firebase Cloud Messaging o Huawei Push Kit. Este valor debe ser obtenido por la aplicación cliente.

- **locationMandatory:** Bandera que determina si la localización es obligatoria o no, con true se valida que el servicio de localización este activo y que se haya dado permisos para acceder a la localización, con false no se hacen las validaciones y se trata de obtener la localización, si no se puede entonces se devuelve valores por defecto (0). Si se envia el valor true y no se puede obtener la localización, ya sea porque el servicio no esta activo o porque no se dieron permisos entonces se lanzará la excepción: VDBLocationException, la aplicación cliente debe controlar la excepción para decidir que hacer en esos casos.

- **locationTimeLimit:** Duración del timeout para obtener datos de la localización.


En el folder `example` se tiene un ejemplo de uso para obtener el secure payload.

Al ejecutar el ejemplo, en pantalla se verá el secure payload obtenido:

![Banner](https://next.viridian.ltd/s/7AGWk2i4k69o5gm/preview)

## Obtención de la versión del Secure Payload

Para obtener el valor de la versión del secure payload, necesario para consumir ciertos endpoints, se tiene disponible la siguiente constante:

``` dart
VdbConstants.version
```

El valor actual, es 1.

## Recepción del codigo de autorización

La aplicación cliente debe configurar la recepción de notificaciones push ya sea por Firebase Cloud Messaging o Huawei Push Kit.

Al recibir una notificación push se debe evaluar la propiedad `type` dentro del objeto `data` de la notificación, si el valor es: `AUTH_CODE`, se trata de una notificación push que contiene un código de autorización (OTP) y se debe usar el SDK de VIRIDIAN para extraer el código de autorización.

Para obtener el "Código de Autorización" u OTP, se debe usar el método `handle` de la clase `PushService`:

Ejemplo con firebase:
``` dart
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String authCode;
      switch (message.data["type"]) {
        case "AUTH_CODE":
          authCode = PushService.handle(
            platform: PlatformsEnum.fcm,
            pushData: message.data,
          );
          break;
        default:
          break;
      }

      // handle authCode var
    });
```

