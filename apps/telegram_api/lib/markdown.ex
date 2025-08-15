defmodule TelegramApi.Markdown do
  @moduledoc """
  A utility module for handling Telegram's MarkdownV2 escaping.
  """

  # According to https://core.telegram.org/bots/api#markdownv2-style
  # The characters '_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!' must be escaped.
  @chars_to_escape ["_", "*", "[", "]", "(", ")", "~", "`", ">", "#", "+", "-", "=", "|", "{", "}", ".", "!"]

  @doc """
  Escapes a string for Telegram's MarkdownV2 format.
  """
  def escape(text) when is_binary(text) do
    Enum.reduce(@chars_to_escape, text, fn char, acc ->
      String.replace(acc, char, "\\" <> char)
    end)
  end

  def escape(text), do: text
end
