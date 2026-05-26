-- ============================================================
--  TESE | Posgrados — Base de Datos
--  Motor: MySQL 8+  |  Codificación: utf8mb4
-- ============================================================

CREATE DATABASE IF NOT EXISTS tese_posgrados
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE tese_posgrados;

-- ============================================================
--  1. PERIODO ESCOLAR
-- ============================================================
CREATE TABLE periodo_escolar (
  id_periodo   INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(60)  NOT NULL,                      -- "Agosto-Diciembre 2026"
  fecha_inicio DATE         NOT NULL,
  fecha_fin    DATE         NOT NULL,
  tipo         ENUM('agosto_diciembre','enero_junio','verano') NOT NULL,
  anio         YEAR         NOT NULL,
  activo       BOOLEAN      NOT NULL DEFAULT FALSE,
  UNIQUE KEY uq_periodo (nombre, anio)
) ENGINE=InnoDB;

-- ============================================================
--  2. PROGRAMA DE POSGRADO
-- ============================================================
CREATE TABLE programa (
  id_programa        INT AUTO_INCREMENT PRIMARY KEY,
  nombre             VARCHAR(200) NOT NULL,
  clave              VARCHAR(20)  NOT NULL UNIQUE,         -- MCIQ, MCIB, MEER…
  nivel              ENUM('maestria','doctorado') NOT NULL,
  duracion_semestres TINYINT      NOT NULL DEFAULT 4,
  creditos_totales   INT          NOT NULL DEFAULT 0,
  activo             BOOLEAN      NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ============================================================
--  3. MATERIA
-- ============================================================
CREATE TABLE materia (
  id_materia      INT AUTO_INCREMENT PRIMARY KEY,
  id_programa     INT          NOT NULL,
  clave           VARCHAR(20)  NOT NULL,
  nombre          VARCHAR(200) NOT NULL,
  creditos        INT          NOT NULL DEFAULT 0,
  horas_doc       INT          NOT NULL DEFAULT 0,         -- DOC
  horas_tis       INT          NOT NULL DEFAULT 0,         -- TIS
  horas_tps       INT          NOT NULL DEFAULT 0,         -- TPS
  semestre        TINYINT      NOT NULL,
  tipo            ENUM('obligatoria','optativa','seminario','investigacion','tesis') NOT NULL,
  UNIQUE KEY uq_materia_prog (clave, id_programa),
  CONSTRAINT fk_mat_prog FOREIGN KEY (id_programa)
    REFERENCES programa(id_programa) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  4. USUARIO (acceso al sistema)
-- ============================================================
CREATE TABLE usuario (
  id_usuario    INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol           ENUM('admin','coordinador','docente','estudiante') NOT NULL,
  activo        BOOLEAN      NOT NULL DEFAULT TRUE,
  ultimo_acceso TIMESTAMP    NULL,
  creado_en     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
--  5. DOCENTE
-- ============================================================
CREATE TABLE docente (
  id_docente       INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario       INT          NOT NULL UNIQUE,
  id_programa      INT          NOT NULL,
  num_empleado     VARCHAR(20)  NOT NULL UNIQUE,
  nombre           VARCHAR(100) NOT NULL,
  ap_paterno       VARCHAR(100) NOT NULL,
  ap_materno       VARCHAR(100),
  grado            ENUM('maestria','doctorado','posdoctorado') NOT NULL,
  especialidad     VARCHAR(200),
  orcid            VARCHAR(50),
  correo_inst      VARCHAR(150),
  antiguedad_anos  INT          NOT NULL DEFAULT 0,
  CONSTRAINT fk_doc_usuario  FOREIGN KEY (id_usuario)
    REFERENCES usuario(id_usuario)  ON DELETE RESTRICT,
  CONSTRAINT fk_doc_programa FOREIGN KEY (id_programa)
    REFERENCES programa(id_programa) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  6. ESTUDIANTE
-- ============================================================
CREATE TABLE estudiante (
  id_estudiante     INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario        INT          NOT NULL UNIQUE,
  id_programa       INT          NOT NULL,
  id_periodo_ingreso INT         NOT NULL,
  num_control       VARCHAR(20)  NOT NULL UNIQUE,
  nombre            VARCHAR(100) NOT NULL,
  ap_paterno        VARCHAR(100) NOT NULL,
  ap_materno        VARCHAR(100),
  fecha_nacimiento  DATE,
  curp              CHAR(18)     UNIQUE,
  correo_personal   VARCHAR(150),
  telefono          VARCHAR(20),
  estado_academico  ENUM('activo','baja_temporal','baja_definitiva',
                         'egresado','titulado') NOT NULL DEFAULT 'activo',
  promedio_general  DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_est_usuario  FOREIGN KEY (id_usuario)
    REFERENCES usuario(id_usuario)   ON DELETE RESTRICT,
  CONSTRAINT fk_est_programa FOREIGN KEY (id_programa)
    REFERENCES programa(id_programa) ON DELETE RESTRICT,
  CONSTRAINT fk_est_periodo  FOREIGN KEY (id_periodo_ingreso)
    REFERENCES periodo_escolar(id_periodo) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  7. GRUPO  (docente + materia + periodo)
-- ============================================================
CREATE TABLE grupo (
  id_grupo    INT AUTO_INCREMENT PRIMARY KEY,
  id_materia  INT         NOT NULL,
  id_docente  INT         NOT NULL,
  id_periodo  INT         NOT NULL,
  clave_grupo VARCHAR(20) NOT NULL,
  cupo_max    INT         NOT NULL DEFAULT 15,
  cupo_actual INT         NOT NULL DEFAULT 0,
  UNIQUE KEY uq_grupo (clave_grupo, id_periodo),
  CONSTRAINT fk_grp_materia FOREIGN KEY (id_materia)
    REFERENCES materia(id_materia)   ON DELETE RESTRICT,
  CONSTRAINT fk_grp_docente FOREIGN KEY (id_docente)
    REFERENCES docente(id_docente)   ON DELETE RESTRICT,
  CONSTRAINT fk_grp_periodo FOREIGN KEY (id_periodo)
    REFERENCES periodo_escolar(id_periodo) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  8. HORARIO DE GRUPO
-- ============================================================
CREATE TABLE horario (
  id_horario  INT AUTO_INCREMENT PRIMARY KEY,
  id_grupo    INT  NOT NULL,
  dia_semana  ENUM('lunes','martes','miercoles','jueves','viernes','sabado') NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin    TIME NOT NULL,
  aula        VARCHAR(50),
  CONSTRAINT fk_hor_grupo FOREIGN KEY (id_grupo)
    REFERENCES grupo(id_grupo) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  9. INSCRIPCIÓN (alumno–grupo)
-- ============================================================
CREATE TABLE inscripcion (
  id_inscripcion    INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante     INT  NOT NULL,
  id_grupo          INT  NOT NULL,
  fecha_inscripcion DATE NOT NULL DEFAULT (CURRENT_DATE),
  estado            ENUM('inscrito','baja','aprobado','reprobado') NOT NULL DEFAULT 'inscrito',
  calificacion_final DECIMAL(4,2),
  UNIQUE KEY uq_inscripcion (id_estudiante, id_grupo),
  CONSTRAINT fk_ins_est  FOREIGN KEY (id_estudiante)
    REFERENCES estudiante(id_estudiante) ON DELETE RESTRICT,
  CONSTRAINT fk_ins_grp  FOREIGN KEY (id_grupo)
    REFERENCES grupo(id_grupo)           ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  10. CALIFICACIÓN PARCIAL
-- ============================================================
CREATE TABLE calificacion_parcial (
  id_calificacion INT AUTO_INCREMENT PRIMARY KEY,
  id_inscripcion  INT         NOT NULL,
  num_parcial     TINYINT     NOT NULL CHECK (num_parcial BETWEEN 1 AND 4),
  calificacion    DECIMAL(4,2) NOT NULL CHECK (calificacion BETWEEN 0.00 AND 100.00),
  fecha_registro  DATE        NOT NULL DEFAULT (CURRENT_DATE),
  UNIQUE KEY uq_parcial (id_inscripcion, num_parcial),
  CONSTRAINT fk_cal_ins FOREIGN KEY (id_inscripcion)
    REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  11. TESIS
-- ============================================================
CREATE TABLE tesis (
  id_tesis          INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante     INT          NOT NULL UNIQUE,
  titulo            VARCHAR(500) NOT NULL,
  resumen           TEXT,
  estado            ENUM('anteproyecto','aprobada','en_desarrollo',
                         'por_defender','defendida','titulado') NOT NULL DEFAULT 'anteproyecto',
  fecha_inicio      DATE,
  fecha_aprobacion  DATE,
  fecha_defensa     DATE,
  calificacion      DECIMAL(4,2),
  CONSTRAINT fk_tes_est FOREIGN KEY (id_estudiante)
    REFERENCES estudiante(id_estudiante) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  12. DIRECTOR / ASESOR DE TESIS
-- ============================================================
CREATE TABLE director_tesis (
  id_tesis   INT NOT NULL,
  id_docente INT NOT NULL,
  rol        ENUM('director','codirector','asesor') NOT NULL DEFAULT 'director',
  PRIMARY KEY (id_tesis, id_docente),
  CONSTRAINT fk_dt_tesis  FOREIGN KEY (id_tesis)
    REFERENCES tesis(id_tesis)     ON DELETE CASCADE,
  CONSTRAINT fk_dt_docente FOREIGN KEY (id_docente)
    REFERENCES docente(id_docente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  13. PAGO
-- ============================================================
CREATE TABLE pago (
  id_pago       INT AUTO_INCREMENT PRIMARY KEY,
  id_estudiante INT           NOT NULL,
  id_periodo    INT           NOT NULL,
  concepto      ENUM('inscripcion','reinscripcion','examen_extra',
                     'titulacion','constancia','otro') NOT NULL,
  monto         DECIMAL(10,2) NOT NULL,
  fecha_pago    DATE          NOT NULL,
  referencia    VARCHAR(100),
  estado        ENUM('pendiente','pagado','cancelado') NOT NULL DEFAULT 'pendiente',
  CONSTRAINT fk_pag_est     FOREIGN KEY (id_estudiante)
    REFERENCES estudiante(id_estudiante) ON DELETE RESTRICT,
  CONSTRAINT fk_pag_periodo FOREIGN KEY (id_periodo)
    REFERENCES periodo_escolar(id_periodo) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  ÍNDICES DE CONSULTA FRECUENTE
-- ============================================================
CREATE INDEX idx_inscripcion_est  ON inscripcion(id_estudiante);
CREATE INDEX idx_inscripcion_grp  ON inscripcion(id_grupo);
CREATE INDEX idx_grupo_periodo    ON grupo(id_periodo);
CREATE INDEX idx_estudiante_prog  ON estudiante(id_programa);
CREATE INDEX idx_pago_est         ON pago(id_estudiante, estado);

-- ============================================================
--  VISTAS ÚTILES
-- ============================================================

-- Historial académico de un alumno
CREATE OR REPLACE VIEW v_historial_alumno AS
SELECT
  e.num_control,
  CONCAT(e.nombre,' ',e.ap_paterno,' ',IFNULL(e.ap_materno,'')) AS alumno,
  p.nombre          AS programa,
  pe.nombre         AS periodo,
  m.clave           AS clave_materia,
  m.nombre          AS materia,
  m.creditos,
  m.semestre,
  i.estado          AS estado_inscripcion,
  i.calificacion_final
FROM inscripcion i
JOIN estudiante   e  ON e.id_estudiante = i.id_estudiante
JOIN grupo        g  ON g.id_grupo      = i.id_grupo
JOIN materia      m  ON m.id_materia    = g.id_materia
JOIN periodo_escolar pe ON pe.id_periodo = g.id_periodo
JOIN programa     p  ON p.id_programa   = e.id_programa
ORDER BY e.num_control, pe.fecha_inicio, m.semestre;

-- Carga académica de docentes
CREATE OR REPLACE VIEW v_carga_docente AS
SELECT
  CONCAT(d.nombre,' ',d.ap_paterno) AS docente,
  d.num_empleado,
  pe.nombre   AS periodo,
  m.nombre    AS materia,
  m.creditos,
  g.clave_grupo,
  g.cupo_actual,
  g.cupo_max
FROM grupo g
JOIN docente       d  ON d.id_docente  = g.id_docente
JOIN materia       m  ON m.id_materia  = g.id_materia
JOIN periodo_escolar pe ON pe.id_periodo = g.id_periodo;

-- ============================================================
--  DATOS DE EJEMPLO (SEED)
-- ============================================================

INSERT INTO periodo_escolar (nombre, fecha_inicio, fecha_fin, tipo, anio, activo) VALUES
  ('Agosto-Diciembre 2025', '2025-08-18', '2025-12-20', 'agosto_diciembre', 2025, FALSE),
  ('Enero-Junio 2026',      '2026-01-19', '2026-06-20', 'enero_junio',      2026, FALSE),
  ('Agosto-Diciembre 2026', '2026-08-24', '2026-12-19', 'agosto_diciembre', 2026, TRUE);

INSERT INTO programa (nombre, clave, nivel, duracion_semestres, creditos_totales) VALUES
  ('Maestría en Ciencias en Ingeniería Química',            'MCIQ', 'maestria',   4, 100),
  ('Maestría en Ciencias en Ingeniería Bioquímica',         'MCIB', 'maestria',   4, 100),
  ('Maestría en Eficiencia Energética y Energías Renovables','MEER','maestria',   4, 100),
  ('Maestría en Gestión Administrativa',                    'MGA',  'maestria',   4,  96),
  ('Maestría en Ciencias en Ingeniería Mecatrónica',        'MCIM', 'maestria',   4,  96),
  ('Maestría en Ingeniería en Sistemas Computacionales',    'MISC', 'maestria',   4,  96),
  ('Doctorado en Ciencias en Ingeniería Bioquímica',        'DIB',  'doctorado',  8, 148);

-- Materias de ejemplo para MCIQ
INSERT INTO materia (id_programa, clave, nombre, creditos, horas_doc, semestre, tipo) VALUES
  (1, 'MCIQ-101', 'Básica I',                     6, 6, 1, 'obligatoria'),
  (1, 'MCIQ-102', 'Básica II',                    6, 6, 1, 'obligatoria'),
  (1, 'MCIQ-103', 'Básica III',                   6, 6, 1, 'obligatoria'),
  (1, 'MCIQ-104', 'Básica IV',                    6, 6, 1, 'obligatoria'),
  (1, 'MCIQ-105', 'Seminario de Investigación I', 4, 4, 1, 'seminario'),
  (1, 'MCIQ-401', 'Tesis',                       40, 0, 4, 'tesis');

-- Usuario admin y demo estudiante
INSERT INTO usuario (email, password_hash, rol) VALUES
  ('admin@tese.edu.mx',    SHA2('Admin2026!', 256), 'admin'),
  ('alumno01@tese.edu.mx', SHA2('1234',       256), 'estudiante'),
  ('docente01@tese.edu.mx',SHA2('Doc2026!',   256), 'docente');

-- Estudiante de ejemplo
INSERT INTO estudiante
  (id_usuario, id_programa, id_periodo_ingreso, num_control,
   nombre, ap_paterno, ap_materno, estado_academico, promedio_general)
VALUES
  (2, 1, 1, 'M21010001', 'María', 'López', 'Hernández', 'activo', 9.20);

-- Docente de ejemplo
INSERT INTO docente
  (id_usuario, id_programa, num_empleado, nombre, ap_paterno, ap_materno,
   grado, especialidad, correo_inst, antiguedad_anos)
VALUES
  (3, 1, 'EMP-001', 'Miguel Ángel', 'Vaca', 'Hernández',
   'doctorado', 'Ingeniería Química y Simulación de Procesos',
   'mvaca@tese.edu.mx', 33);
