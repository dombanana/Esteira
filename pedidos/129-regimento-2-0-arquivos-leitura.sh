#!/usr/bin/env bash
# 129 -- so leitura: arquivos do main da fila (1.0.288) para preparar o regimento 2.0 e conferir o Economico. Sem dado pessoal.
set -u
exec 2>&1
G="git -c safe.directory=* -C /opt/pms-banana-ai-fila.git"
S() { echo "=== FILE $1"; $G show main:SISTEMA/api/app/$1 2>&1; }
echo "main: $($G rev-parse main)"
S reservation/regimento_textos.py
for f in reservation/tests/test_v1245_uso_medicinal.py reservation/tests/test_v1264_silencio_22h_7h.py reservation/tests/test_v1253_regimento_18_airbnb.py reservation/tests/test_v1135_regimento_final.py reservation/tests/test_v1174_regimento_dress_code.py reservation/tests/test_v1138_idiomas_mapa_avisos.py cameras/tests/test_v1247_varanda_armarios_e_regimento.py cameras/tests/test_v1182_cameras_3_dias_e_uma_foto.py reservation/tests/test_v1134_regimento_e_airbnb.py; do S $f; done
echo "=== test_v1160 trecho"; $G show main:SISTEMA/api/app/messaging/tests/test_v1160_treinador_e_ponte_falai.py | sed -n '125,175p'
echo "=== versao.py cabeca"; $G show main:SISTEMA/api/app/versao.py | head -30
echo "=== testes de versao"; $G grep -n -E "HISTORICO|8,|\\\\d\{8" main -- 'SISTEMA/api/app/core/tests/test_versao*.py' 'SISTEMA/api/app/*/tests/test_versao*.py' 2>&1 | head -30
$G ls-tree -r --name-only main SISTEMA/api/app | grep -i "test_versao"
S finance/smart.py
S reservation/perfil_mensagem.py
echo "=== is_smart / economico em regras (fora testes)"; $G grep -n -E "is_smart|ECONOMICO|economico\"|hostel" main -- SISTEMA/api/app | grep -v "/tests/" | grep -v anuncios_airbnb | head -80 | cut -c1-230
echo "=== horarios 18h/10h"; $G grep -n -E "hour=18|hour=10|18, ?0|\(18|\"18:00\"|'18:00'|10:00|CHECKIN_ECO|ECO_" main -- SISTEMA/api/app | grep -v "/tests/" | head -60 | cut -c1-230
echo "=== microondas/quintal/kitchen"; $G grep -n -i -E "micro-?ondas|quintal|\"kitchen\"|'kitchen'|liberdade" main -- SISTEMA/api/app | grep -v "/tests/" | grep -v -E "regimento_textos|regimento.py" | head -80 | cut -c1-230
