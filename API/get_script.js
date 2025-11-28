const fs = require('fs');
const path = require('path');
const ADMIN_TOKEN = "omarkaif"; 

// Указываем путь к папке, где лежат скрипты
const LUA_DIR = path.join(process.cwd(), 'lua_files');

// ... (проверка токена остается прежней)

    // ...
    const scriptName = req.query.name;
    const scriptPath = path.join(LUA_DIR, scriptName);

    // Чтение файла
    try {
        const scriptContent = fs.readFileSync(scriptPath, 'utf8');
        res.setHeader('Content-Type', 'text/plain');
        return res.status(200).send(scriptContent);
    } catch (e) {
        // Ошибка, если файл не найден
        return res.status(404).send(`Скрипт '${scriptName}' не найден на сервере.`);
    }
};
