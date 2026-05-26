/* ============================================================
   TESE | Posgrados — JavaScript compartido
   ============================================================ */

/* ── Acordeón (páginas de programas) ── */
document.querySelectorAll('.acordeon-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const contenido = btn.nextElementSibling;
    const abierto   = contenido.classList.contains('visible');

    /* Cierra todos antes de abrir el seleccionado */
    document.querySelectorAll('.acordeon-contenido').forEach(c => c.classList.remove('visible'));
    document.querySelectorAll('.acordeon-btn').forEach(b => b.classList.remove('abierto'));

    if (!abierto) {
      contenido.classList.add('visible');
      btn.classList.add('abierto');
    }
  });
});

/* ── Portal de Estudiantes: login simple (demo) ── */
const formLogin = document.getElementById('form-login');
if (formLogin) {
  formLogin.addEventListener('submit', e => {
    e.preventDefault();
    const usuario    = document.getElementById('usuario').value.trim();
    const contrasena = document.getElementById('contrasena').value.trim();

    /* Credenciales de demostración */
    if (usuario === 'alumno01' && contrasena === '1234') {
      window.location.href = 'portal_inicio.html';
    } else {
      document.getElementById('error-login').textContent =
        'Usuario o contraseña incorrectos.';
    }
  });
}

/* ── Cerrar sesión ── */
const btnCerrar = document.getElementById('btn-cerrar-sesion');
if (btnCerrar) {
  btnCerrar.addEventListener('click', () => {
    window.location.href = '../estudiantes.html';
  });
}
