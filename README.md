# Sistema de Gestión Académica Multiplataforma

App Flutter + Firebase (plan **Spark**) para administrar **cursos, docentes,
estudiantes, matrículas y calificaciones**, con asistencia por sesión y
jornada del docente. Funciona en Android, web y Windows (la verificación por
SMS solo existe en Android y web).

Único rol: **docente** (el usuario que inicia sesión). Cada curso,
estudiante, matrícula y evaluación guarda su `docenteId` y las reglas de
Firestore solo dejan a cada docente ver y modificar lo suyo.

## Estructura del proyecto

```
lib/
├── main.dart                 Inicializa Firebase y arranca la app
├── app/
│   ├── app.dart              MultiProvider + MaterialApp.router (tema claro/oscuro)
│   ├── app_routes.dart       Nombres de rutas + navegación enviando objetos
│   ├── router.dart           GoRouter con rutas nombradas y redirecciones
│   └── main_shell.dart       Menú lateral (escritorio) / barra inferior + "Más" (móvil)
├── core/
│   ├── constants/            Nombre y versión de la app
│   ├── data/                 Catálogo: 10 carreras con 10 cursos cada una
│   ├── logic/                Reglas en Dart puro: notas, LDI, horario, puntualidad
│   ├── theme/                Paleta y tema Material 3 (claro y oscuro)
│   ├── utils/                Formatos (fechas, notas, %) y texto
│   └── validators/           Validaciones de formularios
├── models/                   Entidades (clases Dart)
│   ├── docente.dart  curso.dart  sesion.dart  estudiante.dart  matricula.dart
│   ├── asistencia.dart  evaluacion.dart  calificacion.dart  jornada.dart
│   └── resumen_asistencia.dart  resumen_notas.dart   (cálculos de promedios y LDI)
├── services/                 Acceso a Firestore
├── providers/                ChangeNotifier compartidos con Provider
│   ├── auth_provider.dart            Sesión y perfil del docente
│   ├── academico_provider.dart       Cursos, estudiantes, matrículas, asistencia
│   ├── calificaciones_provider.dart  Evaluaciones, notas y PROMEDIOS
│   ├── jornada_provider.dart         Entradas y salidas
│   └── tema_provider.dart            Modo claro / oscuro
├── screens/                  Una carpeta por módulo
│   ├── auth/ inicio/ cursos/ estudiantes/ matriculas/ calificaciones/
│   └── reportes/ asistencia/ jornada/ perfil/ ajustes/
└── widgets/                  Widgets reutilizables
    ├── comunes.dart          PageList, AdaptiveGrid, StatTile, EmptyState, …
    ├── encabezado.dart       EncabezadoSeccion y BannerDestacado (Stack)
    ├── academicos.dart       CursoCard, EstudianteTile, NotaBadge, SesionTile, …
    ├── calendario.dart       Calendario mensual propio (agenda y filtro por fechas)
    ├── catalogo_cursos.dart  Selector del catálogo de carreras y cursos
    └── dialogos.dart         Diálogos compartidos
```

## Requisitos del enunciado → dónde se cumplen

| Requisito | Dónde |
|---|---|
| Entidades como **clases Dart** | `models/`: `Docente`, `Curso`, `Estudiante`, `Matricula`, `Evaluacion`, `Calificacion`, `Sesion`, `Asistencia`, `Jornada` |
| **Variables y constantes** | `core/logic/notas.dart` (`notaAprobatoria = 10.5`, `pesoTotal = 100`), `core/logic/ldi.dart` (`umbralLdi = 30`), `models/curso.dart` (límites) |
| **Operadores** | Promedio ponderado `Σ(nota × peso) / Σ(peso)` en `notas.dart`; `??`, `?.`, ternarios en providers y pantallas |
| **Condicionales** | `condicionDe()` y `validarNota()` en `notas.dart`; `switch` de filtros en `cursos_screen.dart`, `registro_notas_screen.dart` |
| **Estructuras repetitivas** | `for` en `promedioPonderado()`, `do-while` en `sugerirCodigoEstudiante()`, `while` en `generarFechasSesiones()` |
| **List** | Listas de cursos, estudiantes, matrículas y el ranking (`ResumenNotasCurso.ranking`) |
| **Map** | Notas `{estudianteId: nota}` en `Evaluacion`, asistencia en `Sesion`, conteo por curso en `matriculas_screen.dart`, índices en `AcademicoProvider` |
| **Set** | Carreras del filtro en `cursos_screen.dart`, códigos ya creados en el catálogo, selección de estudiantes en `matricula_screen.dart`, `AcademicoProvider.matricular()` (sin duplicados), `totalEnLdi` |
| **Widgets reutilizables** | `widgets/` (CursoCard, EstudianteTile, NotaBadge, BannerDestacado, StatTile, …) |
| **StatelessWidget + StatefulWidget** | Stateless: `InicioScreen`, `ReporteScreen`, `CursoCard`. Stateful: `CursosScreen`, `MatriculaScreen`, `RegistroNotasScreen`, … |
| **Container, Row, Column, Stack** | `BannerDestacado` y `EncabezadoSeccion` (círculos e insignia con `Stack`/`Positioned`), `_Distribucion` del reporte, `EmptyState`, vista previa del tema en Ajustes |
| **Rutas nombradas** | `app/app_routes.dart` + `app/router.dart`; se navega con `context.pushNamed(AppRoutes.…)` |
| **Listado, detalle, matrícula y reporte** | `cursos_screen.dart` → `curso_detalle_screen.dart` → `matricula_screen.dart` → `reporte_screen.dart` |
| **Enviar y recibir objetos entre pantallas** | `NavegacionAcademica` en `app_routes.dart`: se envía el `Curso`/`Estudiante`/`Evaluacion` en `extra`; el catálogo envía la `PlantillaCurso` al formulario de curso, la matrícula devuelve `ResultadoMatricula`, el registro de notas devuelve `NotasGuardadas`, el formulario de curso devuelve el `Curso` |
| **setState() en filtros y formularios** | Vista agenda/lista, día y rango en `historial_screen.dart`; carrera elegida en `catalogo_cursos.dart`; búsqueda/filtro/orden en `cursos_screen.dart`, `estudiantes_screen.dart`, `matriculas_screen.dart`; formularios en `registro_notas_screen.dart`, `curso_form_screen.dart`, `matricula_screen.dart` |
| **Provider, ChangeNotifier, Consumer** | `app/app.dart` (`MultiProvider`), `providers/`; `Consumer2<AcademicoProvider, CalificacionesProvider>` en Inicio, Cursos, Calificaciones y Reportes |
| **Compartir cursos, estudiantes y promedios** | `AcademicoProvider` (cursos/estudiantes) y `CalificacionesProvider` (promedios), usados en Inicio, Cursos, Estudiantes, Calificaciones y Reportes |
| **Material Design 3 con estilos propios** | `core/theme/app_theme.dart` (`useMaterial3`, paleta verde azulado + terracota, Outfit + DM Sans, botones píldora) |
| **Modo claro / oscuro dinámico** | `TemaProvider` + `Consumer<TemaProvider>` en `app.dart`; botón en cada encabezado y opción en Ajustes |
| **Multiplataforma** | Android, web y Windows (`firebase_options.dart`); diseño adaptable (menú lateral desde 900 px) |

## Reglas académicas

- **Notas:** escala vigesimal 0–20; se aprueba con **10.50** o más (sin
  redondeo). El promedio es **ponderado** por el peso (%) de cada evaluación;
  los pesos de un curso suman como máximo 100 %.
- **Matrícula:** una por estudiante y curso (id `{cursoId}_{estudianteId}`).
  Al retirarse queda como "retirada" y conserva su historial.
- **Sesiones:** al crear un curso se generan sus fechas reales según los días
  y el horario; dos cursos no pueden cruzarse.
- **LDI:** faltas / total de sesiones del curso ≥ 30 % → el estudiante queda
  bloqueado en ese curso desde la sesión siguiente.
- **Jornada:** una entrada y una salida por sesión, con hora del servidor.
  El historial tiene una **agenda** (calendario con puntos por día:
  completada, sin salida, programada, sin registro) y una lista filtrable.
- **Catálogo:** 10 carreras con 10 cursos predeterminados; al elegir uno
  el formulario de curso llega rellenado (código, nombre, créditos,
  descripción y carrera).
- **Registro:** pide fecha de nacimiento (mayor de 18 años).

## Firestore

| Colección | Contenido |
|---|---|
| `users/{uid}` | Perfil del docente: `firstName`, `lastName`, `dni`, `birthDate`, `phone` (verificado por SMS), `email`, `role: docente`, `status` |
| `cursos/{id}` | `docenteId`, `codigo`, `nombre`, `descripcion`, `carrera`, `creditos`, `totalSesiones`, `diasSemana`, `horaInicio`, `horaFin`, `fechaInicio` |
| `sesiones/{id}` | `docenteId`, `cursoId`, `numero`, `fecha`, horario y `asistencias` `{estudianteId: presente/tarde/falta}` |
| `estudiantes/{id}` | `docenteId`, `codigo`, `nombres`, `apellidos`, `correo` |
| `matriculas/{cursoId}_{estudianteId}` | `docenteId`, `cursoId`, `estudianteId`, `fecha`, `estado` (activa/retirada) |
| `evaluaciones/{id}` | `docenteId`, `cursoId`, `nombre`, `tipo`, `peso`, `fecha`, `notas` `{estudianteId: nota}` |
| `jornadas/{uid}_{sesionId}` | `docenteId`, `cursoId`, `sesionId`, `cursoNombre`, `fecha`, `entrada`, `salida`, horario programado |

Las reglas están en `firestore.rules` (publicar con
`firebase deploy --only firestore:rules`).

## Firebase Console

- Authentication → **Correo/contraseña** y **Teléfono** habilitados.
- Teléfono: número de prueba configurado (plan Spark, sin SMS reales) y
  **Perú** permitido en *Configuración → Política de región de SMS*.
- En modo debug la app desactiva la verificación anti-bots para usar el
  número de prueba.

## Pruebas

`flutter test` ejecuta las pruebas de lógica (notas, LDI, horarios,
matrículas, providers) y de pantallas (rutas nombradas, objetos entre
pantallas, filtros, sin desbordes en 360 px en modo claro y oscuro).
