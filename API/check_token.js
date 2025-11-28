// Этот объект заменяет ваш list.json. 
// В реальном приложении он должен быть в базе данных.
const VALID_TOKENS = [
    { token: "abc123", scripts: ["script_vip.lua", "common_func.lua"] },
    { token: "sub456", scripts: ["common_func.lua"] },
    // Добавьте сюда ваши токены
];

/**
 * Маршрут: /api/check_token
 * Принимает: POST-запрос с токеном пользователя
 * Отдает: Список доступных скриптов
 */
module.exports = async (req, res) => {
    if (req.method !== 'POST') {
        return res.status(405).send('Метод не разрешен. Используйте POST.');
    }

    try {
        const { user_token } = req.body; // Получаем токен из тела запроса (измененная функция chk в Lua)

        if (!user_token) {
            return res.status(400).json({ status: "error", message: "Токен не предоставлен." });
        }

        // Поиск токена в списке
        const foundUser = VALID_TOKENS.find(u => u.token === user_token);

        if (foundUser) {
            // Если токен найден, возвращаем список скриптов
            return res.status(200).json({ 
                status: "success", 
                message: "Пользователь обнаружен.", 
                scripts: foundUser.scripts 
            });
        } else {
            // Если токен не найден
            return res.status(404).json({ 
                status: "not_found", 
                message: "Пользователь не обнаружен.", 
                scripts: []
            });
        }

    } catch (error) {
        console.error("Ошибка обработки токена:", error);
        return res.status(500).json({ status: "error", message: "Внутренняя ошибка сервера." });
    }
};
