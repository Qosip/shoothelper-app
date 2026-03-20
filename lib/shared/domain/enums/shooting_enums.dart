// All enums used by SceneInput and the Settings Engine.
// Defined in skill 06 §2.2.

enum ShootType { photo, video }

enum Environment { outdoorDay, outdoorNight, indoorBright, indoorDark, studio }

enum Subject {
  // MVP
  landscape,
  portrait,
  street,
  architecture,
  macro,
  astro,
  sport,
  wildlife,
  product,
  // V2-07
  concert,
  food,
  realEstate,
  aurora,
  lightning,
  fireworks,
  underwater,
  wedding,
  event,
  droneAerial,
  selfPortrait,
  pet,
  nightCityscape,
  starTrails,
}

enum Intention {
  // MVP
  maxSharpness,
  bokeh,
  freezeMotion,
  motionBlur,
  lowLight,
  // V2-07
  hdrDynamicRange,
  longExposure,
  panning,
  highSpeedSync,
  documentary,
  minimalistNoise,
}

enum LightCondition {
  // MVP
  directSun,
  shade,
  overcast,
  goldenHour,
  blueHour,
  starryNight,
  neon,
  tungsten,
  led,
  // V2-07
  mixedLighting,
  backlit,
  harshMidday,
  diffused,
  candlelight,
  stageLighting,
  moonlight,
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
