#!/usr/bin/env tarantool

-- Удалены ненужные модули: http.server, json, fiber
local log = require('log')

box.cfg{
    listen = 3301, --Настраиваем порт для внешних подключений
    log_level = 5,
}

-- Создание пользователя если не существует
local function create_user()
    -- Поля в кортеже _user (системная таблица в Tarantool):
    -- [1] - id (внутренний идентификатор пользователя)
    -- [2] - owner (владелец/родительский пользователь)
    -- [3] - name (имя пользователя)
    -- [4] - type (тип: 'user' или 'role')
    -- [5] - authentication method (метод аутентификации)
    local user_exists = false
    for _, user in pairs(box.space._user:select()) do
        if user[3] == 'admin' then
            log.info("admin already exists")
            user_exists = true
            break
        end
    end

    if not user_exists then
        box.schema.user.create('admin', {password = 'password'})
        box.schema.user.grant('admin', 'read,write,execute', 'universe')
        log.info("admin created")
    end
end

create_user()

-- Создание спейса для авиабилетов
local function create_flights_space()
    if box.space.flights == nil then
        local flights = box.schema.space.create('flights')

        -- Создание первичного индекса
        flights:create_index('primary', {
            type = 'hash',
            parts = {1, 'unsigned'}
        })

        -- Создание вторичного индекса
        flights:create_index('search_index', {
            type = 'tree',
            parts = {{3, 'string'}, {2, 'string'}, {4, 'string'}} -- departure_date, airline, departure_city
        })

        log.info("Space 'flights' created successfully")
    else
        log.info("Space 'flights' already exists")
    end
end

create_flights_space()

-- Функция для вставки данных
function insert_flight(id, airline, departure_date, departure_city, arrival_city, min_price)
    box.space.flights:insert{id, airline, departure_date, departure_city, arrival_city, min_price}
end

-- Функция для поиска минимальной стоимости по дате
function get_min_price_by_date(date)
    local min_price = nil
    for _, tuple in box.space.flights:pairs() do
        if tuple[3] == date then
            if min_price == nil or tuple[6] < min_price then
                min_price = tuple[6]
            end
        end
    end
    return min_price
end


function get_cheap_flights(coast)
    local result = {}
    for _, tuple in box.space.flights:pairs() do
        if tuple[6] < coast then
            table.insert(result, {
                id = tuple[1],
                airline = tuple[2],
                departure_date = tuple[3],
                departure_city = tuple[4],
                arrival_city = tuple[5],
                min_price = tuple[6]
            })
        end
    end
    return result
end

-- Вставка тестовых данных
local function insert_test_data()
    if box.space.flights:count() == 0 then
        insert_flight(1, 'Aeroflot', '2025-01-01', 'Moscow', 'Paris', 2500)
        insert_flight(2, 'S7', '2025-01-01', 'Moscow', 'London', 3200)
        insert_flight(3, 'Pobeda', '2025-01-01', 'Moscow', 'Berlin', 1800)
        insert_flight(4, 'Lufthansa', '2025-01-02', 'Berlin', 'Moscow', 2800)
        insert_flight(5, 'Turkish Airlines', '2025-01-01', 'Istanbul', 'Moscow', 400)
        log.info("Test data inserted")
    end
end

function get_all_flights()
    local result = {}
    for _, tuple in box.space.flights:pairs() do
        table.insert(result, {
            id = tuple[1],
            airline = tuple[2],
            departure_date = tuple[3],
            departure_city = tuple[4],
            arrival_city = tuple[5],
            min_price = tuple[6]
        })
    end
    return result
end

insert_test_data()

-- Сообщаем, что инициализация завершена
log.info("Tarantool initialized successfully")
log.info("Ready to accept requests on port 3301")