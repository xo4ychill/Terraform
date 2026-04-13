<?php
// ======================================================================
// Страница диагностики подключения к MySQL (Yandex Cloud Managed DB)
// ======================================================================

// Настройки из переменных окружения (передаются через docker-compose)
$db_host     = getenv('DB_HOST') ?: 'localhost';
$db_port     = getenv('DB_PORT') ?: '3306';
$db_name     = getenv('DB_NAME') ?: 'appdb';
$db_user     = getenv('DB_USER') ?: 'appuser';
$db_password = getenv('DB_PASSWORD') ?: '';

// Попытка подключения
$connected = false;
$error_msg = '';
$db_info   = [];

try {
    $dsn = "mysql:host={$db_host};port={$db_port};dbname={$db_name};charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5
    ]);
    $connected = true;

    // Получаем информацию о сервере
    $stmt = $pdo->query("SELECT VERSION() as version, NOW() as now");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $db_info['version'] = $row['version'];
    $db_info['server_time'] = $row['now'];

    // Проверяем наличие таблицы
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);

} catch (PDOException $e) {
    $error_msg = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Статус MySQL</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>🗄️ Статус подключения к MySQL</h1>
        </header>

        <main>
            <section class="card">
                <h2>📊 Параметры подключения</h2>
                <table class="checklist" style="width:100%">
                    <tr><td>🔑 Хост:</td><td><?php echo htmlspecialchars($db_host); ?></td></tr>
                    <tr><td>🔌 Порт:</td><td><?php echo htmlspecialchars($db_port); ?></td></tr>
                    <tr><td>💾 БД:</td><td><?php echo htmlspecialchars($db_name); ?></td></tr>
                    <tr><td>👤 Пользователь:</td><td><?php echo htmlspecialchars($db_user); ?></td></tr>
                    <tr><td>🔒 Пароль:</td><td><?php echo str_repeat('•', 12); ?></td></tr>
                </table>
            </section>

            <?php if ($connected): ?>
                <section class="card" style="border-color: #00ff88;">
                    <h2 style="color: #00ff88;">✅ Подключение успешно!</h2>
                    <table class="checklist" style="width:100%">
                        <tr><td>📦 Версия MySQL:</td><td><?php echo htmlspecialchars($db_info['version']); ?></td></tr>
                        <tr><td>🕐 Время сервера:</td><td><?php echo htmlspecialchars($db_info['server_time']); ?></td></tr>
                        <tr><td>📋 Таблицы:</td><td>
                            <?php if (count($tables) > 0): ?>
                                <?php echo implode(', ', array_map('htmlspecialchars', $tables)); ?>
                            <?php else: ?>
                                <em>Таблиц пока нет (база пуста)</em>
                            <?php endif; ?>
                        </td></tr>
                    </table>
                </section>

                <section class="card">
                    <h2>🧪 Создание тестовой таблицы</h2>
                    <?php
                    try {
                        $pdo->exec("CREATE TABLE IF NOT EXISTS test_table (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            message VARCHAR(255) NOT NULL,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
                        echo '<p style="color:#00ff88;">✅ Таблица <code>test_table</code> создана</p>';

                        $pdo->exec("INSERT INTO test_table (message) VALUES ('Hello from Docker container!')");
                        echo '<p style="color:#00ff88;">✅ Тестовая запись добавлена</p>';

                        $stmt = $pdo->query("SELECT * FROM test_table ORDER BY id DESC LIMIT 5");
                        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                        echo '<table class="checklist" style="width:100%">';
                        echo '<tr><th>ID</th><th>Сообщение</th><th>Создано</th></tr>';
                        foreach ($rows as $row) {
                            echo '<tr>';
                            echo '<td>' . htmlspecialchars($row['id']) . '</td>';
                            echo '<td>' . htmlspecialchars($row['message']) . '</td>';
                            echo '<td>' . htmlspecialchars($row['created_at']) . '</td>';
                            echo '</tr>';
                        }
                        echo '</table>';
                    } catch (PDOException $e) {
                        echo '<p style="color:#ff4444;">❌ Ошибка: ' . htmlspecialchars($e->getMessage()) . '</p>';
                    }
                    ?>
                </section>
            <?php else: ?>
                <section class="card" style="border-color: #ff4444;">
                    <h2 style="color: #ff4444;">❌ Ошибка подключения</h2>
                    <p style="color: #ff8888;"><?php echo htmlspecialchars($error_msg); ?></p>
                    <h3>Возможные причины:</h3>
                    <ul>
                        <li>Сетевая связность между ВМ и MySQL-кластером</li>
                        <li>Неверные учётные данные</li>
                        <li>Брандмауэр или Security Group блокирует порт</li>
                        <li>MySQL-кластер ещё не готов (подождите несколько минут)</li>
                    </ul>
                </section>
            <?php endif; ?>

            <section class="card">
                <p><a href="/">← Назад на главную</a></p>
            </section>
        </main>
    </div>
</body>
</html>
