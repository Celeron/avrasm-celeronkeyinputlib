avrasm-celeronkeyinputlib
===================


НАЗНАЧЕНИЕ:

Библиотека процедур для интеллектуальной обработки ВВОДА: сканирование Кнопок и Энкодеров.
("Intellectual Key/Encoder Input Handling" library)



ОСОБЕННОСТИ:

1) Математическое подавление ошибок, от наведенных электрических помех и дребезга контактов, для всех "физических каналов" подключённых Кнопок и Энкодеров, с заданной и регулируемой величиной помехоустойчивости. (используется оригинальная авторская методика "интегрирующей защёлки": на двунаправленном инкрементальном счётчике)


2) Сложные поведения реальных кнопок - сводятся к стандартизованным кодам в "Регистрах Статуса Кнопок", на основании которых можно легко реализовывать очень сложную и гибкую логику поведения устройства: 

	* распознаются разные "жесты с кнопками": серии нажатий и удержаний кнопок;

	* различаются варианты кнопочных аккордов: одновременное нажатие/удерживание нескольких кнопок;

	* кнопки различается по времени удержания: обычное, "короткое" или "длинное" удержание. А для продвинутых случаев, наиболее функциональных кнопок, также допустимо различать ситуации "сколько КОНКРЕТНО удерживается кнопка, в пределах 0..16сек?" и программировать различные реакции...

	* и что особенно полезно для низкоуровневого ассемблерного кода: дана чёткая и прозрачная методика написания прикладного кода обработчиков "реакции на события" (предлагаются макросы для тестирования и обработки статус-кодов кнопок). Имеется простая возможность назначать одинаковые обработчики различным альтернативным кнопочным жестам. 

	* Простой и понятный механизм "сброса статусных кодов" для уже обработанных кнопок - исключает "побочные эффекты": типа "залипания" или "ошибочные повторные нажания" кнопок... (защита от дурака: при правильно организованном коде обработчиков, пользователь может жать на всё подряд - приложение отреагирует чётко и правильно)


3) Для распознавания и обработки "Кода Грея", поступающего от инкрементального Энкодера по двум физическим каналам - предлагаются три разные реализации кода, обладающие разными функциональными возможностями и подходящие для разных ситуаций (лёгкий и простой код, для хорошего и быстрого железа; или усложнённый код, с коррекцией ошибок, для медленного или сбойного железа).
Разработчик выбирает вариант кода обработки энкодера - только директивами условной компиляции. Вся активность энкодера обрабатывается библиотекой автоматически и сводит все особенности к простому "Счётчику тиков", который затем используется в прикладном коде обработки событий. (Формат счётчика особой специальной структуры не содержит - это просто знаковое целое число: Signed Int = [-128..127].)


4) КОД библиотеки "celeronkeyinputlib.inc" УНИВЕРСАЛЕН и не требует (даже не рекомендует) каких-либо вмешательств и переделок под ваше конкретное устройство! 
Единственная процедура, код которой требуется адаптировать к вашей конкретной физической схеме - это KEY_SCAN_INPUT (через неё осуществляется связь с физическими каналами ввода). 
Также, под вашу конкретную физическую схему, требуется адаптировать блок определения данных в DSEG (см. в файле "data.inc"): определения блоков регистров Интегратора, статусных регистров Кнопок и Энкодеров, и некоторые константы.


5) Данная библиотека испытана в реальном физическом устройстве - и зарекомендовала себя как "реально работоспособная", гибкая и эффективная! Пример использования данной библиотеки, реализация клиентского прикладного кода, приведен в файлах: "example.asm" и "data.inc".




ТРЕБОВАНИЯ И ЗАВИСИМОСТИ:

Данная реализация "Библиотеки процедур для интеллектуальной обработки ВВОДА (celeronkeyinputlib)" написана на языке ассемблера, для компилятора AVRASM. Соответственно, она предназначена для разработки программных прошивок (firmware) на языке ассемблер, для микроконтроллеров Atmel AVR (8-bit).


Используется, и требует подключения, нестандартная внешняя "Библиотека базовых Макроопределений (macrobaselib.inc)" - расширяющая стандартный набор ассемблерных инструкций микроконтроллеров Atmel AVR (8-bit AVR Instruction Set), и рекомендующая парадигму программирования: с хранением "модели прикладных данных" в ОЗУ и использованием нескольких "временных регистров"...
Get code at https://github.com/Celeron/avrasm-macrobaselib




