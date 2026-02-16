# Auditoria Cientifica de Tratamientos PBM - 2026-02-16

## Alcance y criterio
- Catalogo auditado: `DB_DEFINICIONES` en `lib/main.dart` (29 tratamientos base).
- Objetivo: ajustar parametros clinicos conservadores para panel multionda (630/660/810/830/850), priorizando seguridad.
- Regla de interpretacion:
  - `Alta`: multiples RCT + revision sistematica/meta con efecto consistente.
  - `Moderada`: evidencia positiva pero heterogenea o con riesgo de sesgo.
  - `Baja`: pocos RCT, resultados mixtos o indirectos.
  - `Muy baja`: evidencia indirecta/preclinica o sin RCT robustos para esa indicacion.

## Reglas de seguridad global (aplican a todos)
- No irradiar ojos directamente. Usar gafas de proteccion.
- Evitar irradiacion directa sobre tumor activo conocido/sospechado.
- Embarazo: evitar abdomen/pelvis y protocolos sistemicos intensivos.
- Precaucion en epilepsia fotosensible (especialmente protocolos craneales y pulsados).
- Revisar medicacion fotosensibilizante (retinoides, tetraciclinas, etc.).
- En quemaduras abiertas/infectadas o dolor severo progresivo: uso solo con supervision clinica.

## Tabla tratamiento por tratamiento

| ID | Tratamiento | %630 | %660 | %810 | %830 | %850 | Pulso/CW y frecuencia | Duracion | Distancia | Indicaciones | Contraindicaciones relevantes | Evidencia / confianza |
|---|---|---:|---:|---:|---:|---:|---|---|---|---|---|---|
| codo_epi | Epicondilitis (Tenista) | 0 | 25 | 20 | 20 | 35 | CW (preferido); 10 Hz opcional dolor | 10-15 min | 5-15 cm | Dolor lateral de codo por sobreuso tendinoso | Tumor local, herida infectada, fotosensibilidad activa | Moderada |
| codo_golf | Epitrocleitis (Golfista) | 0 | 25 | 20 | 20 | 35 | CW; 10 Hz opcional | 10-15 min | 5-15 cm | Tendinopatia medial de codo | Igual que arriba | Moderada |
| codo_calc | Calcificacion | 0 | 20 | 25 | 20 | 35 | CW | 12-15 min | 5-10 cm | Dolor por tendinopatia calcifica (coadyuvante) | Dolor agudo con sospecha de rotura completa | Baja |
| codo_bur | Bursitis (Apoyo) | 10 | 30 | 20 | 20 | 20 | CW; 10 Hz opcional | 8-12 min | 10-20 cm | Bursitis no septica | Sospecha de bursitis septica/fiebre | Baja |
| esp_cerv | Cervicalgia (Cuello) | 10 | 25 | 20 | 20 | 25 | CW | 12-15 min | 5-15 cm | Dolor cervical mecanico | Radiculopatia progresiva sin evaluacion medica | Moderada |
| esp_dors | Dorsalgia (Alta) | 10 | 25 | 20 | 20 | 25 | CW | 12-15 min | 5-15 cm | Dolor dorsal miofascial | Dolor toracico de posible origen no musculo-esqueletico | Baja |
| esp_lumb | Lumbalgia (Baja) | 10 | 25 | 20 | 20 | 25 | CW | 15-20 min | 5-15 cm | Lumbalgia inespecifica cronica/subaguda | Signos neurologicos severos, sindrome cauda equina | Moderada |
| ant_sobre | Sobrecarga | 0 | 20 | 25 | 25 | 30 | CW | 10-15 min | 10-20 cm | Fatiga/sobrecarga muscular | Lesion aguda grave no diagnosticada | Baja |
| ant_tend | Tendinitis | 0 | 25 | 20 | 20 | 35 | CW; 10 Hz opcional | 10-12 min | 5-15 cm | Tendinopatia de antebrazo | Igual que tendinopatias | Moderada |
| mun_tunel | Tunel Carpiano | 0 | 20 | 30 | 20 | 30 | CW (preferido) | 10-12 min | 5-10 cm | Sintomas leves-moderados de CTS como coadyuvante | Deficit motor progresivo, atrofia tenar | Baja |
| mun_art | Articular (General) | 10 | 25 | 20 | 20 | 25 | CW | 10-12 min | 5-15 cm | Dolor articular inespecifico de muneca | Traumatismo agudo con sospecha de fractura | Baja |
| pierna_itb | Cintilla Iliotibial | 0 | 25 | 20 | 20 | 35 | CW | 12-15 min | 5-15 cm | Dolor lateral por sobreuso (ITB) | Dolor con edema importante o sospecha de desgarro mayor | Moderada-baja |
| pierna_fem | Sobrecarga Femoral | 0 | 20 | 25 | 25 | 30 | CW | 12-15 min | 10-20 cm | Recuperacion muscular post esfuerzo | Lesion muscular aguda severa | Baja |
| pie_fasc | Fascitis Plantar | 0 | 25 | 20 | 20 | 35 | CW | 10-15 min | 5-15 cm | Fascitis plantar cronica/subaguda | Rotura fascial, infeccion local | Moderada |
| pie_esg | Esguince (Dorsal) | 10 | 25 | 20 | 20 | 25 | CW; 10 Hz opcional fase dolor | 10-12 min | 10-20 cm | Esguince leve/moderado en recuperacion | Sospecha de fractura/inestabilidad severa | Baja |
| pie_lat | Lateral (5o Metatarso) | 10 | 20 | 20 | 20 | 30 | CW | 10-12 min | 10-20 cm | Dolor lateral por sobrecarga | Fractura por estres no descartada | Baja |
| homb_tend | Tendinitis (Hombro) | 0 | 25 | 20 | 20 | 35 | CW | 10-15 min | 5-15 cm | Manguito rotador/subacromial (coadyuvante con ejercicio) | Debilidad marcada o rotura completa sospechada | Moderada |
| rod_gen | General/Menisco | 0 | 20 | 20 | 20 | 40 | CW | 10-15 min | 5-15 cm | Dolor de rodilla degenerativo (OA) | Bloqueo mecanico severo/trauma agudo | Moderada |
| piel_cicat | Cicatrices | 30 | 50 | 0 | 0 | 20 | CW | 8-12 min | 15-25 cm | Cicatriz postquirurgica/hipertrofica temprana | Cicatriz infectada activa | Moderada-baja |
| piel_acne | Acne | 20 | 80 | 0 | 0 | 0 | CW | 8-12 min | 15-25 cm | Acne inflamatorio leve-moderado (coadyuvante) | Acne nodulo-quistico severo sin manejo dermatologico | Moderada-baja |
| piel_quem | Quemaduras | 30 | 40 | 0 | 10 | 20 | CW | 5-8 min | 20-30 cm | Quemadura superficial/2o grado en fase no complicada | Quemadura profunda, infeccion, necrosis | Baja (en humanos), moderada preclinica |
| fat_front | Grasa Abdomen Frontal | 70 | 30 | 0 | 0 | 0 | CW | 15-20 min | 5-15 cm | Contorno corporal estetico (coadyuvante) | Embarazo, hernia, cancer activo local | Baja-moderada |
| face_rejuv | Facial Rejuvenecimiento | 40 | 50 | 0 | 0 | 10 | CW | 8-12 min | 20-30 cm | Fotoenvejecimiento y arruga fina | Dermatitis activa, fotosensibilidad, sin gafas | Moderada |
| testo | Testosterona | 0 | 10 | 45 | 15 | 30 | CW (experimental) | 3-5 min | 20-30 cm | No recomendado como protocolo estandar por evidencia insuficiente | Cancer testicular/prostatico, dolor escrotal no estudiado, fertilidad en estudio | Muy baja |
| sueno | Sueno / Melatonina | 60 | 40 | 0 | 0 | 0 | CW (noche) | 15-20 min | 30-50 cm indirecta | Higiene de sueno y relajacion nocturna | Trastorno bipolar no controlado, fotosensibilidad | Baja |
| sis_energ | Energia Sistemica | 10 | 30 | 20 | 20 | 20 | CW | 10-15 min | 15-30 cm | Fatiga inespecifica (coadyuvante) | Causa medica no evaluada de fatiga | Baja |
| sis_circ | Circulacion | 10 | 30 | 20 | 20 | 20 | CW | 15-20 min | 15-30 cm | Sensacion de mala perfusion/musculo cansado | TVP sospechada, isquemia critica, infeccion activa | Baja |
| cab_migr | Migrana | 0 | 20 | 30 | 20 | 30 | CW; 10 Hz opcional | 8-12 min | 15-25 cm (nuca/frontal sin ojos) | Migrana/tensional como coadyuvante | Epilepsia fotosensible, aura atipica nueva | Baja |
| cab_brain | Salud Cerebral | 0 | 0 | 60 | 20 | 20 | CW (preferido); 40 Hz experimental | 8-12 min | 20-30 cm frontal | Cognicion/sueno en protocolo experimental | Epilepsia fotosensible, trastorno psiquiatrico no estabilizado | Baja-moderada |

## Notas de implementacion practica
- La mayor parte de la evidencia PBM clinica reporta mejor consistencia con `CW` que con una frecuencia fija de pulso para estas indicaciones.
- Para dolor musculoesqueletico, si CW no es tolerado o no responde, se puede probar pulso 10 Hz como estrategia empirica.
- Para craneal (migra/cognicion/sueno), empezar con dosis bajas y progresar por tolerancia.
- Donde el tratamiento sea `Baja` o `Muy baja`, usarlo como coadyuvante, no como sustituto de evaluacion medica.

## Fuentes principales (prioridad: revisiones sistematicas/RCT)
- WALT dosage recommendations: https://waltpbm.org/documentation-links/recommendations/
- Knee OA meta-analysis (2024): https://pubmed.ncbi.nlm.nih.gov/38775202/
- Lower extremity tendinopathy/plantar fasciitis meta-analysis (2022): https://pubmed.ncbi.nlm.nih.gov/36171024/
- Neck pain meta-analysis (2009): https://pubmed.ncbi.nlm.nih.gov/19913903/
- Chronic low back pain meta-analysis (2016): https://pubmed.ncbi.nlm.nih.gov/27207675/
- Tendinopathy systematic review (2009): https://pubmed.ncbi.nlm.nih.gov/19708800/
- Shoulder impingement PBM + exercise review (2025): https://pubmed.ncbi.nlm.nih.gov/40365684/
- Carpal tunnel Cochrane review (updated 2022): https://pubmed.ncbi.nlm.nih.gov/35611937/
- Acne blue light systematic review (2021): https://pubmed.ncbi.nlm.nih.gov/34696155/
- Acne blue+red RCT (2000): https://pubmed.ncbi.nlm.nih.gov/10809858/
- Scar prevention LED 830 nm RCT (2022): https://pubmed.ncbi.nlm.nih.gov/36045183/
- Burn wounds systematic review/meta (2024): https://pubmed.ncbi.nlm.nih.gov/39172550/
- Second-degree burns 904 nm RCT (2026): https://pubmed.ncbi.nlm.nih.gov/40992752/
- Facial rejuvenation RCT (2023): https://pubmed.ncbi.nlm.nih.gov/36780572/
- Photoaging exploratory RCT (2025): https://pubmed.ncbi.nlm.nih.gov/41091280/
- Primary headache PBM systematic review (2022): https://pubmed.ncbi.nlm.nih.gov/35054491/
- Chronic migraine laser add-on pilot RCT (2024): https://pubmed.ncbi.nlm.nih.gov/39198866/
- tPBM cognition human systematic review (2023): https://pubmed.ncbi.nlm.nih.gov/36371017/
- tPBM cognition meta-analysis (2025): https://pubmed.ncbi.nlm.nih.gov/40394373/
- Insomnia RCT (2025): https://pubmed.ncbi.nlm.nih.gov/41125953/
- Male infertility LLLT systematic review (2023): https://pubmed.ncbi.nlm.nih.gov/38028870/
- Body contouring 635 nm RCT (2009): https://pubmed.ncbi.nlm.nih.gov/20014253/
- Body contouring/spot fat RCT (2011): https://pubmed.ncbi.nlm.nih.gov/20393809/
- Microcirculation RCT (2020): https://pubmed.ncbi.nlm.nih.gov/32064652/
- Endothelial function trial (2023): https://pubmed.ncbi.nlm.nih.gov/37072603/
- PBM oncologic safety review (2023): https://pubmed.ncbi.nlm.nih.gov/36722207/
- PBM tumor safety review (2019): https://pubmed.ncbi.nlm.nih.gov/31109692/
- tPBM dose-dependent tolerability RCT (2025): https://pubmed.ncbi.nlm.nih.gov/40437278/

## Estado de esta auditoria
- Completa para 29/29 tratamientos del catalogo actual.
- Lista para fase 2: traducir esta tabla a datos de app (`frecuencias`, `hz`, `duracion`, `posicion`, `prohibidos`) con versionado y changelog.
