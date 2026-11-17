# CaptionProof

> **«Subtítulos revisados, no solo generados»**

![Android](https://img.shields.io/badge/Android-Offline--First-4338CA)
![Flutter](https://img.shields.io/badge/Flutter-Material%203-blue)
![Zero Telemetry](https://img.shields.io/badge/Telemetr%C3%ADa-0%25-success)

**CaptionProof** es un revisor y editor **offline-first** de archivos de subtítulos `.srt` y `.vtt` diseñado para detectar errores técnicos antes de publicar un vídeo.

---

## Características principales

- **Importación local `.srt` y `.vtt`**: abre archivos desde el dispositivo o pega contenido directamente.
- **Validador automático de calidad (QC)**:
  - Solapamientos de tiempo entre cues consecutivos (`OVERLAP`).
  - Rangos invertidos (`TIME_ORDER`).
  - Velocidad de lectura excesiva superior a 20 caracteres/segundo (`HIGH_CPS`).
  - Líneas mayores de 42 caracteres (`LINE_TOO_LONG`) o más de 2 líneas (`TOO_MANY_LINES`).
- **Edición y exportación**: corrige el texto de cada cue y exporta archivos `.srt` o `.vtt` limpios.
- **IA opcional BYOK (gratuita)**: desactivada por defecto.

---

## Instalación y compilación local

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

---

## Documentación adicional

- [DEPENDENCIES.md](DEPENDENCIES.md) · [CONTRIBUTING.md](CONTRIBUTING.md)
