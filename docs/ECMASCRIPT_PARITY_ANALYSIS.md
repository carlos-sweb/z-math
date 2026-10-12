# Análisis de paridad con ECMAScript

Fecha: 2026-10-12. Implementación auditada: commit `7959ea4`.
Referencia normativa: ECMAScript 2026, sección 21.3, objeto Math.

## Resultado

El repositorio todavía no cumple el objetivo de paridad semántica al 100%,
incluso restringiendo el alcance al núcleo numérico de Math.
Contiene las 37 funciones y las 8 constantes de Math de ES2026, pero esa
cobertura de API no demuestra conformidad completa.

El alcance declarado en el README es una biblioteca numérica Zig sobre f64,
para ser utilizada desde un intérprete. No es una implementación completa del
lenguaje ECMAScript ni del objeto JavaScript Math.

## 1. hypot: desbordamiento y subdesbordamiento intermedios

`src/zmath.zig`, función `hypot`, calcula directamente la suma de `v * v`
y después su raíz cuadrada. Esto pierde resultados representables:

| Entrada | Repositorio | Node v26.5.0 |
| --- | --- | --- |
| `hypot([1e308])` | `Infinity` | `1e308` |
| `hypot([1e308, 1e308])` | `Infinity` | `1.4142135623730951e308` |
| `hypot([1e-300])` | `+0` | `1e-300` |
| `hypot([1e-300, 1e-300])` | `+0` | `1.4142135623730952e-300` |
| `hypot([5e-324])` | `+0` | `5e-324` |

Necesita un algoritmo con escalado para evitar el desbordamiento y el
subdesbordamiento de los cuadrados. La especificación advierte sobre la pérdida
de precisión de implementaciones ingenuas. La prioridad de Infinity sobre NaN
está contemplada correctamente en el código y en las pruebas existentes.

## 2. sumPrecise: signo incorrecto del cero

`sumPrecise` devuelve +0 para una entrada vacía, una entrada [-0] y una entrada
[-0, -0]. ECMAScript exige -0 para las tres. La diferencia es observable mediante
`Object.is(resultado, -0)` o `1 / resultado`.

La prueba existente de [-0, -0] usa `std.testing.expectEqual`, que compara los
floats mediante igualdad numérica y no distingue +0 de -0. Por eso pasa aunque
el signo sea incorrecto. Las pruebas deben comprobar `std.math.signbit` o los bits.
La prueba existente de la entrada vacía espera explícitamente +0.

La API está documentada como un núcleo de suma de valores finitos: delega NaN,
infinidades y otros casos especiales al llamador. El comentario original menciona
`math_builtins.zig`, que no está incluido en este repositorio. Esa integración
podría resolver los casos especiales, pero no se puede acreditar desde aquí.

## 3. Semántica JavaScript que corresponde a la integración

Las funciones reciben f64 o slices de f64. La conformidad del objeto Math requiere
verificar también la capa de integración del intérprete:

- ToNumber, ToPrimitive, argumentos omitidos, símbolos, BigInt y excepciones.
- Orden de conversión y efectos secundarios de los argumentos de max, min e hypot.
- Descriptores de propiedades, name, length y Symbol.toStringTag.
- Para sumPrecise: iterables, rechazo de valores que no sean Number, cierre del
  iterador ante errores, estados de NaN/infinidades y límite de elementos.
- Para random: distribución y secuencias distintas entre realms; la biblioteca
  recibe un RNG externo y no gestiona los realms.

Delegar estos comportamientos es coherente con el alcance de la biblioteca.
Sin pruebas de la integración no se puede afirmar paridad completa con Math.

## 4. Validación realizada

Plataforma: Linux x86_64. Las comprobaciones adicionales se ejecutaron fuera
de la suite del repositorio, sin cambiar el comportamiento de la implementación.

- Zig 0.16.0, Debug: 16/16 pruebas existentes pasan.
- Zig 0.16.0, ReleaseSafe: 16/16 pruebas existentes pasan.
- Zig 0.17.0, Debug: 16/16 pruebas existentes pasan.
- Comparación de 1.582 casos con Node v26.5.0, sobre entradas numéricas,
  incluidos NaN, infinidades, ceros con signo, subnormales y valores límite.
  Se encontraron 22 diferencias: exp (1), cosh (3), pow (12) e hypot (6).
- Las 25 comprobaciones de valores finitos de Test262
  `test/built-ins/Math/sumPrecise/sum.js`, adaptadas a Zig y comparadas por bits,
  pasan. Esto no equivale a ejecutar toda la suite Test262 de sumPrecise.
- Tres comprobaciones independientes del signo del cero en sumPrecise fallan.
- Node v26.5.0 dispone de Math.f16round pero no de Math.sumPrecise; la suma se
  contrastó con Test262 y la especificación, no con una función inexistente de Node.

Las diferencias numéricas frente a V8 en funciones aproximadas no demuestran por
sí solas un incumplimiento de ECMAScript. La especificación permite resultados
implementation-approximated en varias funciones. No se debe confundir conformidad
con igualdad bit a bit respecto de un motor concreto.

La muestra no es exhaustiva y no permite asignar un porcentaje de conformidad.
El repositorio no contiene un ejecutor de Test262, una matriz de conformidad por
función ni resultados de pruebas en múltiples arquitecturas.

## 5. Documentación y versión objetivo

Debe fijarse una edición de ECMAScript para que el objetivo sea verificable.
El comentario original de sumPrecise mezcla ES2025 y Stage 3, aunque la función
está incluida en ES2026. También debe diferenciarse una biblioteca numérica
orientada a ECMAScript de una implementación acreditada como plenamente conforme.

## Prioridades para alcanzar el objetivo

1. Corregir hypot mediante escalado y añadir casos de overflow, underflow y subnormales.
2. Resolver y documentar los casos especiales de sumPrecise, especialmente -0.
3. Comparar los ceros por signo o bits en las pruebas de conformidad.
4. Incorporar pruebas reproducibles de Test262 con un commit y edición fijados.
5. Verificar la integración JavaScript y publicar una matriz de conformidad.
6. Validar los casos exactos y especiales en más arquitecturas y modos de compilación.

## Referencias

- [ECMAScript 2026: Math](https://tc39.es/ecma262/2026/multipage/numbers-and-dates.html#sec-math-object).
- [Math.hypot](https://tc39.es/ecma262/2026/multipage/numbers-and-dates.html#sec-math.hypot).
- [Math.sumPrecise](https://tc39.es/ecma262/2026/multipage/numbers-and-dates.html#sec-math.sumprecise).
- [Test262: sumPrecise/sum.js](https://github.com/tc39/test262/blob/main/test/built-ins/Math/sumPrecise/sum.js).
- [Algoritmo de referencia TC39](https://github.com/tc39/proposal-math-sum/blob/main/polyfill/polyfill.mjs).
