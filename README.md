# Описание
Результат работы команды «Kizil» над проверкой модуля матричного АЛУ в рамках Инженерного хакатона SoC Design Challenge 2024 по треку «Функциональная верификация».

Новость: https://www.abiturient.ru/news/163743

# Структура репозитория:

    ./SoC-Design2024/
        ./doc/ -- здесь хранится спецификация и другие полезные материалы
        
        ./dut/ -- здесь хранится DUT (RTL)
            ./ymp_alu_matrix_top.sv
            ./ymp_alu_regs.sv
            ./ymp_alu_control_unit.sv
            
        ./tb/ -- здесь хранится TB
            ymp_alu_matrix_tb.sv
        
        ./run.sh -- срипт запуска симуляции 
        ./tb_files.lst -- файл-список исходников
