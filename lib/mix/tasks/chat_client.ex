defmodule Mix.Tasks.ChatClient do
  @moduledoc """
  Mix task to start a chat client.
  """

  use Mix.Task

  import Chat.Protocol

  alias Chat.Message.{Broadcast, Register}

  def run([] = _args) do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: :once])

    user = Mix.shell().prompt("Enter your username: ") |> String.trim()

    encoded_message = %Register{username: user}
    |> encode_message()

    :ok = :gen_tcp.send(socket, encoded_message)

    receive_loop(user, socket, spawn_prompt_task(user))
  end

  defp spawn_prompt_task(username) do
    Task.async(fn -> Mix.shell().prompt("#{username} > ") end)
  end

  defp receive_loop(username, socket, %Task{ref: ref} = prompt_task) do
    receive do
      {^ref, message} ->
        broadcast = %Broadcast{from_username: username, contents: message}
        :ok = :gen_tcp.send(socket, encode_message(broadcast))
        receive_loop(username, socket, spawn_prompt_task(username))

      {:DOWN, ^ref, _, _} ->
        Mix.raise("Prompt task exited unexpectedly")

      {:tcp, ^socket, data} ->
        :ok = :inet.setopts(socket, active: :once)
        handle_data(data)
        receive_loop(username, socket, prompt_task)

      {:tcp_closed, ^socket} ->
        IO.puts("Server closed the connection")

      {:tcp_error, ^socket, reason} ->
        Mix.raise("TCP error: #{inspect(reason)}")
    end
  end

  defp handle_data(data) do
    case decode_message(data) do
      {:ok, %Broadcast{} = message, ""} ->
        IO.puts("\n#{message.from_username}: #{message.contents}")

      _other ->
        Mix.raise("Expected a complete broadcast message and nothing else. but got: #{inspect(data)}")
    end
  end
end
