const ADMIN_TOKEN = "omarkaif"; // Ваш секретный токен для загрузки!

// СИМУЛЯЦИЯ ФАЙЛОВОЙ СИСТЕМЫ: Ваши скрипты хранятся здесь
const SCRIPTS_STORAGE = {
    "common_func.lua": 
        `print("[LOADER] Загружены общие функции!") 
        function show_status() print("Статус: OK") end`,
    
    "script_vip.lua": 
        `print("[LOADER] Загружен VIP-скрипт!") 
        show_status()`,

    // Добавьте сюда остальные скрипты
    "other_script.lua": 
        `print("[LOADER] Загружен другой скрипт")`
};

/**
 * Маршрут: /api/get_script?name=script.lua
 * Принимает: GET-запрос с секретным токеном в заголовке
 * Отдает: Содержимое запрошенного скрипта
 */
module.exports = async (req, res) => {
    // 1. Проверка секретного токена администратора (omarkaif)
    const token = req.headers.authorization;
    if (!token || token !== `Bearer ${ADMIN_TOKEN}`) {
        return res.status(401).send('Неверный или отсутствующий токен. Доступ запрещен.');
    }

    // 2. Получение имени файла из URL-параметров
    const scriptName = req.query.name;

    if (!scriptName) {
        return res.status(400).send('Не указано имя скрипта.');
    }
    
    // 3. Поиск скрипта в симулированном хранилище
    const scriptContent = SCRIPTS_STORAGE[scriptName];

    if (!scriptContent) {
        return res.status(404).send(`Скрипт '${scriptName}' не найден.`);
    }

    // 4. Отправка содержимого скрипта (Plain Text)
    res.setHeader('Content-Type', 'text/plain');
    return res.status(200).send(scriptContent);
};
