import 'package:flutter_test/flutter_test.dart';
import 'package:raph/shared/models/sintoma.dart';
import 'package:raph/shared/services/sintoma_scoring_service.dart';

void main() {
  test('Scoring Service evalua correctamente casos clinicos criticos', () {
    final catalogo = [
      Sintoma(id: 1, codigo: '101', nombre: 'PARO CARDIO RESPIRATORIO', codigoColor: 'ROJO'),
      Sintoma(id: 2, codigo: '103', nombre: 'PERDIDA DE CONOCIMIENTO', codigoColor: 'ROJO'),
      Sintoma(id: 3, codigo: '107', nombre: 'CONVULSIONES', codigoColor: 'ROJO'),
      Sintoma(id: 4, codigo: '108', nombre: 'PRECORDALGIA O DOLOR DE PECHO', codigoColor: 'ROJO'),
      Sintoma(id: 5, codigo: '116', nombre: 'ACCIDENTE VEHICULAR', codigoColor: 'ROJO'),
      Sintoma(id: 6, codigo: '206', nombre: 'DOLOR TORACICO', codigoColor: 'AMARILLO'),
      Sintoma(id: 7, codigo: '210', nombre: 'TX DE CRANEO', codigoColor: 'AMARILLO'),
      Sintoma(id: 8, codigo: '308', nombre: 'FIEBRE', codigoColor: 'VERDE'),
    ];

    // Caso 1: Paciente inconsciente que NO respira -> Debe sugerir 101 PARO en primer lugar
    final resParo = SintomaScoringService.evaluarSugerencias(
      catalogo: catalogo,
      conciencia: ConcienciaOption.inconsciente,
      respiracion: RespiracionOption.noRespira,
    );
    expect(resParo.isNotEmpty, true);
    expect(resParo.first.sintoma.codigo, '101');
    expect(resParo.first.porcentajeMatch, greaterThan(90));

    // Caso 2: Paciente alerta, respira normal, dolor en el pecho -> Debe sugerir 108 / 206 y DESCARTAR 101
    final resPecho = SintomaScoringService.evaluarSugerencias(
      catalogo: catalogo,
      conciencia: ConcienciaOption.alerta,
      respiracion: RespiracionOption.normal,
      causa: CausaOption.clinico,
      focoPrincipal: 'pecho',
    );
    expect(resPecho.isNotEmpty, true);
    expect(resPecho.any((r) => r.sintoma.codigo == '101'), false);
    expect(resPecho.first.sintoma.codigo, isIn(['108', '206']));

    // Caso 3: Accidente vehicular -> Debe sugerir 116
    final resVehicular = SintomaScoringService.evaluarSugerencias(
      catalogo: catalogo,
      conciencia: ConcienciaOption.alerta,
      respiracion: RespiracionOption.normal,
      causa: CausaOption.trauma,
      focoPrincipal: 'accidente_vehicular',
    );
    expect(resVehicular.isNotEmpty, true);
    expect(resVehicular.first.sintoma.codigo, '116');
  });
}
