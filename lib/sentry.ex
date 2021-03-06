defmodule Sentry do
  alias Sentry.{Event, Client}
  require Logger


  @moduledoc """
    Provides the basic functionality to submit a `Sentry.Event` to the Sentry Service.

    ### Configuration

    Add the following to your production config

        config :sentry,
          dsn: "https://public:secret@app.getsentry.com/1",
          included_environments: [:prod],
          environment_name: :prod
          tags: %{
            env: "production"
          }

    ### Capturing Exceptions

    Simply calling `capture_exception\2` will send the event.

        Sentry.capture_exception(my_exception)

    ### Configuring The `Logger` Backend

    See `Sentry.Logger`

  """

  @doc """
    Parses and submits an exception to Sentry if current environment is in included_environments.
  """
  @spec capture_logger_message(String.t) :: {:ok, String.t} | :error
  def capture_logger_message(message) do
    message
    |> Event.transform_logger_stacktrace()
    |> send_event()
  end

  @doc """
    Parses and submits an exception to Sentry if current environment is in included_environments.
  """
  @spec capture_exception(Exception.t, Keyword.t) :: {:ok, String.t} | :error
  def capture_exception(exception, opts \\ []) do
    exception
    |> Event.transform_exception(opts)
    |> send_event()
  end

  @doc """
    Sends a `Sentry.Event`
  """
  @spec send_event(%Event{}) :: {:ok, String.t} | :error
  def send_event(%Event{message: nil, exception: nil}) do
    Logger.warn("unable to parse exception")
    {:ok, "Unable to parse as exception, ignoring..."}
  end

  def send_event(event = %Event{}) do
    included_environments = Application.fetch_env!(:sentry, :included_environments)
    if Application.fetch_env!(:sentry, :environment_name) in included_environments do
      Client.send_event(event)
    else
      {:ok, ""}
    end
  end
end
