// All enums used by SceneInput and the Settings Engine.
// Defined in skill 06 §2.2.

enum ShootType { photo, video }

enum Environment { outdoorDay, outdoorNight, indoorBright, indoorDark, studio }

enum Subject {
  landscape,
  portrait,
  street,
  architecture,
  macro,
  astro,
  sport,
  wildlife,
  product,
}

enum Intention { maxSharpness, bokeh, freezeMotion, motionBlur, lowLight }

enum LightCondition {
  directSun,
  shade,
  overcast,
  goldenHour,
  blueHour,
  starryNight,
  neon,
  tungsten,
  led,
}

enum SubjectMotion { still, slow, fast, veryFast }

enum SubjectDistance { veryClose, close, medium, far, infinity }

enum Mood { dramatic, soft, highContrast, natural, silhouette }

enum Support { handheld, tripod, monopod, gimbal }

enum DofPreference { shallow, medium, deep }

enum AfAreaOverride { center, wide, tracking, eyeAf }

enum BracketingMode { none, exposure, focus }

enum FileFormatOverride { raw, jpeg, rawPlusJpeg }

enum WbOverride { auto, daylight, shade, cloudy, tungsten, fluorescent, flash }

// --- Engine output enums ---

enum AfMode { afS, afC, dmf, mf }

enum AfArea { wide, zone, center, spot, expandedSpot, tracking, eyeAf }

enum MeteringMode { multi, centerWeighted, spot, highlight }

enum WbPreset {
  auto,
  daylight,
  shade,
  cloudy,
  tungsten,
  fluorescent,
  flash,
  underwater,
}

enum DriveMode { single, continuousHi, continuousMid, continuousLo, selfTimer, bracket }

enum ExposureMode { p, a, s, m }

enum Confidence { high, medium, low }

enum CompromiseType { noise, motionBlur, depthOfField, exposure, gearLimit, impossible }

enum CompromiseSeverity { info, warning, critical }

enum SensorSize { apsc, fullFrame, microFourThirds }
