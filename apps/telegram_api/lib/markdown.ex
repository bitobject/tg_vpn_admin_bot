defmodule TelegramApi.Markdown do
  @moduledoc """
  A simple helper for escaping Telegram "Markdown" special characters.
  """

  @escape_chars [
    "_",
    "*",
    "[",
    "]",
    "(",
    ")",
    "~",
    "`",
    ">",
    "#",
    "+",
    "-",
    "=",
    "|",
    "{",
    "}",
    ".",
    "!"
  ]

  @doc """
  Escapes all special "Markdown" characters in a string.
  """
  def escape(text) when is_binary(text) do
    Enum.reduce(@escape_chars, text, fn char, acc ->
      String.replace(acc, char, "\\" <> char)
    end)
  end

  def escape(text), do: text
end
