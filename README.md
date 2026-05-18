# Education-Programme-Data-Engineering-2026-Cívica-Proyect
Este proyecto consiste en la construcción de un pipeline de datos moderno, confiable y escalable,  datos desde Fuente de datos de APIs/Datasets -> archivos CSV  hacia un almacén de datos en la nube. Utilizando  dlt para la ingesta y modelado de datos crudos, Snowflake como motor de almacenamiento y  computo,  dbt para la transformación 

## Caso ficticio de Cliente 
### 1. Contexto de Necesidades del Cliente

Una empresa cliente quiere apostar fuerte por integrar modelos de Inteligencia Articial generativa en varios ámbitos de su negocio (atención al cliente, soporte interno, análisis de documentos y generación de código). Antes de comprometerse con un proveedor o una arquitectura concreta, necesita entender en profundidad el panorama de modelos disponibles, sus capacidades y sus costes, para tomar decisiones informadas y sostenibles a medio y largo plazo.

Para ello, la empresa solicita construir una plataforma analítica que consolide información de múltiples proveedores de LLM (OpenAI, Anthropic,Google, Meta, etc.) y de diferentes modelos (GPT-4o, Claude 3.5, Gemini,Llama, Phi, entre otros). Esta plataforma debe recoger datos sobre precios por token, tipos de planes disponibles, tamaños de ventana de contexto, soporte multimodal, si el modelo es open source o propietario, así como resultados en distintos benchmarks de calidad (por ejemplo, MMLU para conocimiento general, GPQA para razonamiento avanzado y métricas de coding para programación).

El **objetivo** del cliente es disponer de una visión 360 del mercado de modelos de IA que le permita responder preguntas clave como: 


* _¿Qué modelo ofrece mejor relación calidad/precio para nuestro uso concreto en un area de competencia?_
* _¿Cómo han evolucionado los precios de los modelos a lo largo del tiempo y qué tendencias se observan por proveedor o por tipo de modelo?_
* _Para tareas de razonamiento complejo, ¿qué modelos ofrecen el mejor equilibrio rendimiento/precio y cuál ha mejorado más en el último año?_
* _Por proveedor, ¿qué familias de modelos han bajado más de precio en los últimos 6,12 meses y en qué regiones se nota más la bajada?_


Sobre esta base, se desarrollarán casos de uso analíticos y visualizaciones que permitan a perfiles técnicos y de negocio comparar modelos, simular costes mensuales según escenarios de uso y seleccionar la combinación óptima de modelos y proveedores para cada área del negocio.

#### 1.1.Terminos en el contexto de Modelos de IA
* **Token(input)** Fragmento de texto que envías al modelo
* **Token (output)** Texto generado por el modelo
* **Context Window** Context Window Máximo de tokens que el modelo puede "ver.a la vez (input + output)
* **MMLU Massive Multitask Language Understanding**: benchmark que evalúa al modelo en 57 materias (STEM, derecho, medicina, humanidades. . . ) con preguntas de opción múltiple.
* **MMLU-Pro:** Variante más exigente del MMLU con 10 opciones de respuesta en lugar de 4, diseñada para seguir diferenciando modelos de alta capacidad una vez que el MMLU estándar pierde discriminación. 
* **MMMU-Pro:** Massive Multi-discipline Multimodal Understanding Pro. Evalúa razonamiento visual en 1.730 tareas que combinan texto e imágenes en múltiples disciplinas. Es el benchmark de referencia para modelos multimodales.
* **GPQA Graduate-Level Google-Proof Q&A**: preguntas de biología, física y química diseñadas para que NO se puedan buscar en Google. Incluso expertos del área cometen errores
* **GPQA Diamond:** El conjunto "Diamond" es el subconjunto más difícil del benchmark GPQA, con 198 preguntas de nivel de doctorado.
* **Coding** Benchmark de capacidad de programación (LiveCodeBench o HumanEval).Mide qué % de problemas de código resuelve correctamente.
* **HumanEval:** Benchmark de programación que mide la capacidad del modelo para completar funciones Python con tests unitarios. Evalúa el porcentaje de problemas resueltos correctamente en el primer intento (pass@1). Actualmente considerado saturado por los modelos más avanzados.
* **SWE-bench Verified:** Software Engineering Benchmark. Evalúa la capacidad del modelo para resolver issues reales de GitHub en 500 tareas verificadas. Mide el porcentaje de issues resueltos correctamente, representando escenarios de ingeniería de software reales.
* **LiveCodeBench:** Benchmark de programación diseñado para ser libre de contaminación de datos, al utilizar problemas de código publicados después de las fechas de entrenamiento de los modelos. Contiene 880 problemas y evalúa con pass@1. Es el benchmark de coding más relevante para evitar memorización.
* **MATH-500:** Subset de 500 problemas de competición matemática (AMC, AIME) de nivel avanzado. Mide la capacidad de resolución de problemas matemáticos complejos. Considerado saturado por los modelos frontier actuales.
* **AIME 2025:** American Invitational Mathematics Examination 2025. Examen de matemáticas de competición de 30 problemas. Es actualmente el diferenciador más relevante en el rango frontier, ya que los problemas son de alta dificultad y aún no están saturados.
* **GSM8K:** Grade School Math 8K. Conjunto de 8.500 problemas matemáticos de nivel de escuela primaria. Considerado saturado por los modelos actuales (muchos alcanzan >97%).
* **Chatbot Arena Elo:** Puntuación Elo derivada de evaluaciones humanas ciegas y pareadas en la plataforma LMSYS Chatbot Arena. A diferencia de los benchmarks anteriores, no mide una tarea específica sino la preferencia humana global. No tiene límite superior fijo; valores más altos indican mayor preferencia humana.
* **IFEval:** Instruction Following Evaluation. Evalúa en 541 tareas si el modelo sigue instrucciones con restricciones verificables (por ejemplo, "responde en menos de 100 palabras" o "usa exactamente 3 párrafos"). Mide la capacidad de seguimiento preciso de instrucciones.
* **HellaSwag:** Benchmark de razonamiento de sentido común basado en completar frases. Con 10.042 ejemplos, evalúa si el modelo elige la continuación más plausible de una descripción de actividad cotidiana. Actualmente saturado.
* **ARC-AGI v2:** Abstraction and Reasoning Corpus, versión 2. Mide inteligencia fluida y reconocimiento de patrones novedosos en 400 tareas. Es el benchmark más exigente para evaluar razonamiento abstracto genuino, ya que los problemas no pueden resolverse mediante memorización. Los modelos frontier aún están lejos de la puntuación humana.
* **BIG-Bench Hard:** Subconjunto de 23 tareas del benchmark BIG-Bench que fueron identificadas como especialmente difíciles para los modelos del momento. Evalúa razonamiento multi-paso, lógica y tareas complejas que requieren múltiples capacidades simultáneas.
* **Benchmark saturado:** Un benchmark se considera saturado cuando los modelos más avanzados han alcanzado puntuaciones cercanas al máximo posible, perdiendo así su capacidad para diferenciar entre modelos de alta capacidad. Los benchmarks saturados siguen siendo útiles para comparar modelos de gama media o baja.
* **Multimodal** Si el modelo puede procesar imágenes, audio o vídeo además de texto
* **Open Source / Open Weight** Si los pesos del modelo son públicos (Llama 4, Phi-4,Gemma. . . ) frente a propietario (GPT, Claude) Un modelo puede tener arquitectura conocida pero pesos cerrados, o viceversa.
* **Provider:** Empresa que sirve el modelo: a veces el creador (OpenAI con GPT),a veces un tercero (Fireworks, Together AI sirviendo Llama)
* **Reasoning model:** Modelos que "piensanäntes de responder (o1, o3,DeepSeek R1). Generan muchos más output tokens, son más caros pero más precisos en tareas complejas
* **Architecture:** Tipo de arquitectura neural del modelo. Los modelos **Dense Transformer** activan todos sus parámetros en cada inferencia. Los modelos **MoE (Mixture of Experts)** tienen un mayor número de parámetros totales pero solo activan una fracción de ellos por token, lo que les permite combinar alta capacidad con eficiencia computacional.
* **Active Parameters:** En modelos MoE, el número de parámetros que realmente se activan durante la inferencia, frente al total de parámetros del modelo. Por ejemplo, DeepSeek V3 tiene 671B parámetros totales pero solo 37B activos por token.
* **Training Data Cutoff:** Fecha hasta la cual llegan los datos con los que fue entrenado el modelo. Información posterior a esa fecha es desconocida para el modelo a menos que se le proporcione en el contexto.
* **Intelligence Index:** Índice compuesto de inteligencia (escala 0–100+) calculado a partir de evaluaciones múltiples, que resume el rendimiento general de un modelo en una única puntuación comparativa. Los valores marcados con "E" son estimaciones extrapoladas.
* **TTFT (Time To First Token):** Tiempo hasta que el modelo genera el primer token de respuesta, expresado en milisegundos o segundos. Es un indicador clave de la experiencia de usuario percibida en aplicaciones interactivas.
* **Throughput:** Velocidad de generación del modelo, expresada en tokens por segundo. Determina cuánto texto puede generar el modelo por unidad de tiempo en condiciones de producción.
* **Tasa de toxicidad (toxicity score):** porcentaje de respuestas con contenido tóxico detectado.
* **Tasa de alucinación (hallucination rate):** porcentaje de respuestas que contienen información inventada o incorrecta.
* **Tasa de seguimiento de instrucciones (instruction following):** porcentaje de veces que el modelo sigue correctamente las  instrucciones del usuario.
* **Resistencia a jailbreak (jailbreak resistance):** porcentaje de intentos de evasión de filtros que el modelo resiste con éxito.
* **puntuación de factualidad (factuality score):** porcentaje de afirmaciones factuales correctas y verificables.


#### 1.2 Requisitos después de Analizar los requisitos

El sistema de información debe modelar el dominio de decisión sobre modelos de Inteligencia Artificial generativa para permitir a la empresa cliente analizar y comparar distintas opciones de proveedores y modelos en términos de precio, capacidades y adecuación a varios escenarios de uso internos. 

El sistema debe registrar los **proveedores** que ofrecen modelos de IA a través de API o servicios gestionados. Cada proveedor tiene un identificador único, un nombre.Cada proveedor puede ofrecer cero, uno o varios modelos.

El sistema debe identificar de forma única cada modelo de IA ofrecido por un proveedor. Cada **modelo** tiene un identificador único, una referencia al proveedor al que pertenece, un nombre comercial, una familia o serie (GPT, Claude, Gemini, Llama, Phi, etc.), un tamaño de ventana de contexto en tokens, un indicador de si es multimodal (sí/no), un indicador de si es open source o propietario y opcionalmente una fecha de lanzamiento. Cada modelo pertenece a exactamente un proveedor. Cada modelo puede tener uno o varios planes de precios asociados.

El sistema debe representar los distintos tipos de **benchmark** utilizados para evaluar los modelos (por ejemplo, MMLU, GPQA, benchmarks de coding). Cada tipo de benchmark tiene un identificador, un código o nombre corto (MMLU, GPQA, CODING, etc.), una descripción y una indicación de la area de competencia que evalúa (conocimiento general, razonamiento, programación, etc.).
Un modelo puede ser evaluado en varios tipos de benchmark. Un tipo de benchmark puede aplicarse a muchos modelos. 

El sistema debe almacenar los **resultados que obtiene** cada modelo en cada tipo de **benchmark**. Cada resultado tiene un identificador, una referencia al modelo evaluado, una referencia al tipo de benchmark aplicado, una puntuación o métrica obtenida (por ejemplo, un porcentaje), una fecha y versión de la evaluación. Cada plan de precios puede tener distintos precios a lo largo del tiempo, Cada precio corresponde a un único plan de precios y una fecha determinada.

El sistema debe contemplar que un mismo modelo puede ofrecerse bajo distintos **planes de precios** (por ejemplo: estándar, batch, reasoning, región específica). Cada plan de precios tiene un identificador, una referencia al modelo al que aplica, un nombre o tipo de plan (standard, batch, reasoning, etc.) y una unidad de facturación principal (por ejemplo, "tokens"). Cada plan de precios se define para un único modelo.

El sistema debe permitir almacenar el **precio** específco de cada plan de un modelo en una fecha determinada. Cada registro de precio tiene un identificador, una referencia al plan de precios correspondiente, una fecha de vigencia, un precio por millón de tokens de entrada, un precio por millón de tokens de salida y una moneda (por defecto USD, pero extensible).

El sistema debe almacenar métricas de **rendimiento operativo** que complementan los benchmarks de calidad y son determinantes para la viabilidad de un modelo en producción. Estas métricas no miden la inteligencia del modelo sino su comportamiento como servicio. como pueden ser Intelligence Index,throughput, TTFT

El sistema debe contemplar la **evaluación de seguridad** y comportamiento responsable para cada modelo, especialmente relevante en casos de uso regulados como atención al cliente, soporte interno y análisis de documentos.


 

El sistema debe contemplar la posibilidad de que la empresa cliente opte por desplegar modelos de IA de código abierto (open weight) en infraestructura propia contratada a proveedores de computación en la nube, en lugar de consumirlos a través de una API gestionada. Este escenario, conocido como despliegue on-premises en nube o self-hosted cloud, es especialmente relevante para modelos como Llama 4, Mistral, DeepSeek, Qwen o Gemma, cuyos pesos son públicos y pueden ejecutarse en hardware arrendado sin depender del proveedor original del modelo.

Para dar soporte a este caso de uso, el sistema debe registrar los modelos de GPU disponibles en el mercado, ya que son el recurso computacional determinante para ejecutar modelos de lenguaje de gran tamaño. Cada GPU tiene un identificador único, un nombre de modelo (por ejemplo, NVIDIA H100 SXM, A100 80GB o AMD MI300X), una arquitectura, la cantidad de VRAM en gigabytes, el ancho de banda de memoria en GB/s, el consumo eléctrico en vatios (TDP) y el rendimiento en operaciones de punto flotante de precisión media (FP16 TFLOPs), que determina directamente la velocidad de inferencia alcanzable.

El sistema debe registrar asimismo los servidores que los proveedores de computación en la nube ponen a disposición para ejecutar estos modelos. Cada servidor tiene un identificador único, una referencia al proveedor de nube que lo ofrece, una referencia al modelo de GPU que incorpora, un nombre o referencia de instancia (por ejemplo, p4de.24xlarge en AWS o a3-highgpu-8g en Google Cloud), la VRAM total disponible en el servidor (suma de todas las GPU del nodo), la RAM del sistema en gigabytes y el precio mensual de arrendamiento en la moneda correspondiente.

Para que la empresa cliente pueda comparar el coste real de desplegar un modelo open weight según el proveedor de nube elegido, el sistema debe registrar los precios de GPU por proveedor de forma independiente a la configuración de cada servidor. Cada registro de precio de GPU por proveedor contiene una referencia al proveedor, una referencia al modelo de GPU, el tipo de proveedor (hiperescalador como AWS, Azure o Google Cloud); el precio por hora en modalidad on-demand, el precio por hora en modalidad spot (instancias interrumpibles con descuento significativo), las tarifas de egress de datos en precio por gigabyte transferido fuera de la plataforma y la moneda de facturación.

La información consolidada permite a la plataforma responder preguntas como: 
_¿cuántas GPU H100 necesito para servir Llama 4 Maverick a 100 usuarios concurrentes y cuánto me cuesta por hora en cada proveedor de nube?_
_¿Qué diferencia de coste existe entre ejecutar DeepSeek V3 en instancias on-demand frente a spot en AWS, Azure y CoreWeave? ¿Qué proveedor ofrece el menor coste total incluyendo transferencia de datos para un volumen mensual estimado de X tokens generados? _
Estas capacidades analíticas complementan el análisis de precios por API y permiten a la empresa evaluar de forma informada si el despliegue propio de modelos open weight resulta más económico o ventajoso que el consumo a través de API gestionada, en función del volumen de uso, los requisitos de latencia, la soberanía del dato y las necesidades de personalización del modelo.
