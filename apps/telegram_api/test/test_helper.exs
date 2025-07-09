ExUnit.start()

# Настройка sandbox для интеграционных тестов с Core.Repo
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)
