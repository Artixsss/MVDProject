# 🚀 Быстрый старт с OpenRouter

## ✅ Что сделано

1. ✅ Создан `OpenRouterService.cs` - новый AI сервис
2. ✅ Добавлен API ключ в `appsettings.json`
3. ✅ Обновлен `Program.cs` для использования OpenRouter
4. ✅ **Больше НЕ НУЖЕН VPN!** 🎉

---

## 🔧 Запуск

```bash
cd backend
dotnet run
```

**Ожидается:**
```
info: Program[0]
      MVD Backend API Starting
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://0.0.0.0:5029
```

---

## 🧪 Тест

1. Откройте http://localhost:5029
2. Найдите `POST /api/CitizenRequests/analyze`
3. Отправьте:
```json
{
  "description": "У меня украли телефон"
}
```

**Результат (через 1-2 секунды):**
```json
{
  "category": "Имущественные преступления",
  "priority": "Средний",
  "sentiment": "Негативный",
  "summary": "Заявление о краже телефона",
  "suggestedAction": "Зарегистрировать обращение..."
}
```

---

## 🎯 Что используется

- **API:** OpenRouter (https://openrouter.ai)
- **Модель:** MiniMax M2 (бесплатная)
- **Идентификатор модели:** `minimax/minimax-m2:free`
- **Лимит:** 200 запросов/день
- **VPN:** ❌ НЕ ТРЕБУЕТСЯ!

---

## 🔄 Переключение моделей

Откройте `backend/Services/OpenRouterService.cs`, строка 22:

```csharp
private const string MODEL = "minimax/minimax-m2:free";
```

**Другие бесплатные модели:**
- `"google/gemini-2.0-flash-exp:free"` - Google Gemini (через OpenRouter)
- `"meta-llama/llama-3.2-3b-instruct:free"` - Meta Llama
- `"mistralai/mistral-7b-instruct:free"` - Mistral AI

Просто измените и перезапустите бекенд!

---

## 📊 Мониторинг

Статистика использования API:  
👉 https://openrouter.ai/activity

---

## ⚠️ Важно

**API ключ в `appsettings.json`:**
```json
"OpenRouter": {
  "ApiKey": "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"
}
```

**Не делитесь этим ключом публично!**

---

## 🎉 Готово!

Проект работает с MiniMax через OpenRouter **БЕЗ VPN**!

Подробнее: `backend/InfoProject/ПЕРЕХОД НА OPENROUTER.md`

