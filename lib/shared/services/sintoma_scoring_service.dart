import '../models/sintoma.dart';

/// Opciones para los filtros del screening asistido
enum ConcienciaOption {
  alerta,
  confuso,
  inconsciente,
}

enum RespiracionOption {
  normal,
  dificultosa,
  noRespira,
}

enum HemorragiaOption {
  ninguna,
  moderada,
  severa,
}

enum CausaOption {
  clinico,
  trauma,
  intoxicacion,
  violencia,
  saludMental,
  obstetrico,
}

class SintomaScoreResult {
  final Sintoma sintoma;
  final int score;
  final double porcentajeMatch;
  final List<String> razones;

  const SintomaScoreResult({
    required this.sintoma,
    required this.score,
    required this.porcentajeMatch,
    required this.razones,
  });
}

class SintomaScoringService {
  /// Evalúa las 83 fichas según las respuestas del operador y devuelve las sugerencias ordenadas por coincidencia.
  static List<SintomaScoreResult> evaluarSugerencias({
    required List<Sintoma> catalogo,
    ConcienciaOption? conciencia,
    RespiracionOption? respiracion,
    HemorragiaOption? hemorragia,
    CausaOption? causa,
    String? focoPrincipal,
  }) {
    if (catalogo.isEmpty) return [];

    // Si no se respondió ninguna pregunta aún, retornar lista vacía (sin sugerencias activas)
    if (conciencia == null &&
        respiracion == null &&
        hemorragia == null &&
        causa == null &&
        (focoPrincipal == null || focoPrincipal.isEmpty)) {
      return [];
    }

    final List<SintomaScoreResult> resultados = [];

    for (var s in catalogo) {
      final codigo = s.codigo.trim();
      int score = 0;
      final List<String> razones = [];
      bool descartado = false;

      // =====================================================================
      // 1. EVALUACIÓN DE RESPIRACIÓN (VITAL)
      // =====================================================================
      if (respiracion != null) {
        if (respiracion == RespiracionOption.noRespira) {
          if (codigo == '101') {
            score += 150;
            razones.add('Ausencia de respiración (Paro cardiorrespiratorio)');
          } else if (codigo == '118') {
            score += 110;
            razones.add('Posible inmersión/asfixia');
          } else if (codigo == '122') {
            score += 110;
            razones.add('Posible ahorcamiento/asfixia');
          } else if (s.codigoColor?.toUpperCase() != 'ROJO') {
            // Descartar automáticamente fichas amarillas y verdes si el paciente no respira
            descartado = true;
          }
        } else if (respiracion == RespiracionOption.dificultosa) {
          if (codigo == '101') {
            // Si respira (aunque con dificultad), no es paro
            descartado = true;
          } else if (codigo == '112') {
            score += 95;
            razones.add('Dificultad respiratoria aguda (Disnea)');
          } else if (codigo == '109') {
            score += 85;
            razones.add('Compromiso oxigenatorio (Cianosis)');
          } else if (codigo == '228') {
            score += 70;
            razones.add('Sospecha de cuerpo extraño en vía aérea');
          } else if (codigo == '313' || codigo == '314') {
            score += 45;
            razones.add('Afección de vías respiratorias');
          }
        } else if (respiracion == RespiracionOption.normal) {
          if (codigo == '101' || codigo == '118' || codigo == '122') {
            descartado = true;
          }
        }
      }

      // =====================================================================
      // 2. EVALUACIÓN DE CONCIENCIA (VITAL)
      // =====================================================================
      if (conciencia != null && !descartado) {
        if (conciencia == ConcienciaOption.inconsciente) {
          if (codigo == '103') {
            score += 100;
            razones.add('Pérdida de conocimiento / Inconsciente');
          } else if (codigo == '101' && respiracion == RespiracionOption.noRespira) {
            score += 50;
            razones.add('Inconsciencia asociada a paro');
          } else if (codigo == '107') {
            score += 70;
            razones.add('Inconsciencia post-convulsión');
          } else if (codigo == '104') {
            score += 65;
            razones.add('Compromiso severo de la conciencia');
          } else if (s.codigoColor?.toUpperCase() == 'VERDE') {
            // Un paciente inconsciente no puede ser código verde
            score -= 80;
          }
        } else if (conciencia == ConcienciaOption.confuso) {
          if (codigo == '104') {
            score += 90;
            razones.add('Confusión / Obnubilación / Desorientación');
          } else if (codigo == '106') {
            score += 80;
            razones.add('Dificultad neurológica para expresarse');
          } else if (codigo == '219') {
            score += 70;
            razones.add('Alteración de conducta');
          } else if (codigo == '229') {
            score += 65;
            razones.add('Posible hipoglucemia / descompensación DBT');
          }
        } else if (conciencia == ConcienciaOption.alerta) {
          if (codigo == '101' || codigo == '103') {
            descartado = true;
          } else if (codigo == '222') {
            // Pérdida de conocimiento ya recuperada
            score += 50;
          }
        }
      }

      // =====================================================================
      // 3. EVALUACIÓN DE HEMORRAGIA
      // =====================================================================
      if (hemorragia != null && !descartado) {
        if (hemorragia == HemorragiaOption.severa) {
          if (codigo == '123') {
            score += 120;
            razones.add('Hemorragia severa activa');
          } else if (codigo == '111') {
            score += 90;
            razones.add('Sangrado profuso en politraumatismo');
          } else if (codigo == '113' || codigo == '114') {
            score += 90;
            razones.add('Hemorragia por herida de arma');
          }
        } else if (hemorragia == HemorragiaOption.moderada) {
          if (codigo == '209') {
            score += 85;
            razones.add('Herida cortante sangrante');
          }
        }
      }

      // =====================================================================
      // 4. EVALUACIÓN DE CAUSA (TRAUMA VS CLÍNICO VS OTROS)
      // =====================================================================
      if (causa != null && !descartado) {
        final esTraumaFicha = _esFichaTrauma(codigo);
        final esClinicoFicha = _esFichaClinica(codigo);
        final esToxicoFicha = (codigo == '121' || codigo == '208');
        final esViolenciaFicha = (codigo == '113' || codigo == '114' || codigo == '127' || codigo == '226');
        final esObstetricoFicha = (codigo == '227');

        if (causa == CausaOption.trauma) {
          if (esTraumaFicha) {
            score += 40;
          } else if (esClinicoFicha && codigo != '102') {
            score -= 60; // Penalizar patología clínica pura ante evento traumático
          }
        } else if (causa == CausaOption.clinico) {
          if (esClinicoFicha) {
            score += 35;
          } else if (esTraumaFicha) {
            descartado = true; // Descartar accidentes si fue un problema clínico puro
          }
        } else if (causa == CausaOption.intoxicacion) {
          if (esToxicoFicha) {
            score += 80;
            razones.add('Causa toxicológica/química');
          }
        } else if (causa == CausaOption.violencia) {
          if (esViolenciaFicha) {
            score += 80;
            razones.add('Episodio de violencia o agresión');
          }
        } else if (causa == CausaOption.obstetrico) {
          if (esObstetricoFicha) {
            score += 120;
            razones.add('Evento obstétrico');
          }
        }
      }

      // =====================================================================
      // 5. EVALUACIÓN DEL FOCO PRINCIPAL O REGIÓN AFECTADA
      // =====================================================================
      if (focoPrincipal != null && focoPrincipal.isNotEmpty && !descartado) {
        switch (focoPrincipal) {
          case 'pecho':
            if (codigo == '108') {
              score += 110;
              razones.add('Dolor opresivo precordial (Rojo)');
            } else if (codigo == '206') {
              score += 105;
              razones.add('Dolor torácico característico (Amarillo)');
            } else if (codigo == '202' || codigo == '223' || codigo == '225') {
              score += 80;
              razones.add('Palpitaciones / arritmia cardíaca');
            } else if (codigo == '212') {
              score += 70;
              razones.add('Traumatismo torácico');
            }
            break;

          case 'neurologico_acv':
            if (codigo == '105') {
              score += 120;
              razones.add('Pérdida súbita de fuerza en extremidades (ACV)');
            } else if (codigo == '106') {
              score += 120;
              razones.add('Dificultad o imposibilidad para hablar (ACV)');
            } else if (codigo == '104') {
              score += 70;
              razones.add('Alteración neurológica central');
            }
            break;

          case 'convulsiones':
            if (codigo == '107') {
              score += 140;
              razones.add('Crisis convulsiva / Espasmos musculares');
            }
            break;

          case 'abdomen':
            if (codigo == '207') {
              score += 110;
              razones.add('Dolor abdominal agudo');
            } else if (codigo == '213') {
              score += 85;
              razones.add('Traumatismo abdominal');
            } else if (codigo == '304' || codigo == '305') {
              score += 75;
              razones.add('Náuseas y vómitos');
            } else if (codigo == '323') {
              score += 65;
              razones.add('Diarrea');
            }
            break;

          case 'fiebre':
            if (codigo == '308') {
              score += 120;
              razones.add('Síndrome febril');
            } else if (codigo == '318') {
              score += 80;
              razones.add('Escalofríos asociados a fiebre');
            } else if (codigo == '309' || codigo == '310') {
              score += 65;
              razones.add('Malestar general');
            }
            break;

          case 'cefalea_mareos':
            if (codigo == '303') {
              score += 100;
              razones.add('Cefalea / Dolor de cabeza');
            } else if (codigo == '301') {
              score += 90;
              razones.add('Mareos / Inestabilidad');
            }
            break;

          case 'accidente_vehicular':
            if (codigo == '116') {
              score += 130;
              razones.add('Colisión o siniestro vehicular');
            } else if (codigo == '111') {
              score += 90;
              razones.add('Politraumatismo de tránsito');
            }
            break;

          case 'caida_altura':
            if (codigo == '115') {
              score += 130;
              razones.add('Precipitación / Caída de altura');
            } else if (codigo == '111') {
              score += 85;
              razones.add('Politraumatismo por caída');
            }
            break;

          case 'trauma_craneo':
            if (codigo == '210') {
              score += 120;
              razones.add('Traumatismo encéfalo craneano');
            }
            break;

          case 'trauma_miembros':
            if (codigo == '211') {
              score += 120;
              razones.add('Traumatismo en brazos o piernas');
            }
            break;

          case 'herida_cortante':
            if (codigo == '209') {
              score += 120;
              razones.add('Herida cortante');
            }
            break;

          case 'quemaduras':
            if (codigo == '217') {
              score += 130;
              razones.add('Quemadura térmica / química');
            }
            break;

          case 'electrocucion':
            if (codigo == '117') {
              score += 130;
              razones.add('Descarga eléctrica / Electrocución');
            }
            break;

          case 'intoxicacion_ingesta':
            if (codigo == '208') {
              score += 130;
              razones.add('Ingestión de medicamentos o tóxicos');
            }
            break;

          case 'gases_toxicos':
            if (codigo == '121') {
              score += 130;
              razones.add('Inhalación de gases / monóxido');
            }
            break;

          case 'arma_fuego':
            if (codigo == '114') {
              score += 140;
              razones.add('Impacto de proyectil de arma de fuego');
            }
            break;

          case 'arma_blanca':
            if (codigo == '113') {
              score += 140;
              razones.add('Herida punzocortante por arma blanca');
            }
            break;

          case 'suicidio':
            if (codigo == '127') {
              score += 140;
              razones.add('Intento de autoeliminación');
            }
            break;

          case 'diabetes':
            if (codigo == '229') {
              score += 120;
              razones.add('Descompensación metabólica diabética');
            }
            break;

          case 'parto':
            if (codigo == '227') {
              score += 140;
              razones.add('Trabajo de parto inminente');
            }
            break;

          case 'sincope_recuperado':
            if (codigo == '222') {
              score += 120;
              razones.add('Pérdida transitoria ya recuperada');
            }
            break;

          case 'lumbalgia_dorso':
            if (codigo == '306') {
              score += 100;
              razones.add('Dolor lumbar');
            } else if (codigo == '214') {
              score += 80;
              razones.add('Traumatismo dorsolumbar');
            }
            break;

          case 'urinario':
            if (codigo == '307' || codigo == '316') {
              score += 100;
              razones.add('Dificultad o síntomas urinarios');
            }
            break;

          case 'alergia_piel':
            if (codigo == '319') {
              score += 110;
              razones.add('Reacción alérgica cutánea / Ronchas');
            } else if (codigo == '317') {
              score += 90;
              razones.add('Prurito / Picazón');
            }
            break;
        }
      }

      if (!descartado && score > 0) {
        // Calcular porcentaje normalizado con un techo de 140 puntos
        final pct = (score / 140.0 * 100.0).clamp(15.0, 99.0);
        resultados.add(
          SintomaScoreResult(
            sintoma: s,
            score: score,
            porcentajeMatch: pct,
            razones: razones,
          ),
        );
      }
    }

    // Ordenar de mayor a menor puntaje
    resultados.sort((a, b) => b.score.compareTo(a.score));

    // Retornar máximo las 6 más coincidentes para no abrumar al operador
    return resultados.take(6).toList();
  }

  static bool _esFichaTrauma(String codigo) {
    const traumaCodes = {
      '111', '113', '114', '115', '116', '117', '119', '120', '126',
      '209', '210', '211', '212', '213', '214', '215', '216', '217'
    };
    return traumaCodes.contains(codigo);
  }

  static bool _esFichaClinica(String codigo) {
    const clinicoCodes = {
      '101', '103', '104', '105', '106', '107', '108', '109', '110', '112',
      '202', '203', '204', '205', '206', '207', '218', '222', '223', '224', '225', '229',
      '301', '302', '303', '304', '305', '306', '307', '308', '309', '310',
      '313', '314', '315', '316', '317', '318', '319', '320', '321', '322', '323', '324', '325', '326', '327'
    };
    return clinicoCodes.contains(codigo);
  }
}
