defmodule FarmbotCeleryScript.Compiler.PinControl do
  alias FarmbotCeleryScript.Compiler

  def write_pin(%{args: %{pin_number: num, pin_mode: mode, pin_value: value}}, cs_scope) do
    quote location: :keep do
      pin = unquote(Compiler.celery_to_elixir(num, cs_scope))
      mode = unquote(Compiler.celery_to_elixir(mode, cs_scope))
      value = unquote(Compiler.celery_to_elixir(value, cs_scope))

      with :ok <- FarmbotCeleryScript.SysCalls.write_pin(pin, mode, value) do
        me = unquote(__MODULE__)
        me.conclude(pin, mode, value)
      end
    end
  end

  # compiles read_pin
  def read_pin(%{args: %{pin_number: num, pin_mode: mode}}, cs_scope) do
    quote location: :keep do
      pin = unquote(Compiler.celery_to_elixir(num, cs_scope))
      mode = unquote(Compiler.celery_to_elixir(mode, cs_scope))
      FarmbotCeleryScript.SysCalls.read_pin(pin, mode)
    end
  end

  # compiles set_servo_angle
  def set_servo_angle(
        %{args: %{pin_number: pin_number, pin_value: pin_value}}, cs_scope) do
    quote location: :keep do
      pin = unquote(Compiler.celery_to_elixir(pin_number, cs_scope))
      angle = unquote(Compiler.celery_to_elixir(pin_value, cs_scope))
      FarmbotCeleryScript.SysCalls.log("Writing servo: #{pin}: #{angle}")
      FarmbotCeleryScript.SysCalls.set_servo_angle(pin, angle)
    end
  end

  # compiles set_pin_io_mode
  def set_pin_io_mode(
        %{args: %{pin_number: pin_number, pin_io_mode: mode}}, cs_scope) do
    quote location: :keep do
      pin = unquote(Compiler.celery_to_elixir(pin_number, cs_scope))
      mode = unquote(Compiler.celery_to_elixir(mode, cs_scope))
      FarmbotCeleryScript.SysCalls.log("Setting pin mode: #{pin}: #{mode}")
      FarmbotCeleryScript.SysCalls.set_pin_io_mode(pin, mode)
    end
  end

  def toggle_pin(%{args: %{pin_number: pin_number}}, _cs_scope) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.toggle_pin(unquote(pin_number))
    end
  end

  def conclude(pin, 0, _value) do
    FarmbotCeleryScript.SysCalls.read_pin(pin, 0)
  end

  def conclude(pin, _mode, value) do
    FarmbotCeleryScript.SysCalls.log("Pin #{pin} is #{value} (analog)")
  end
end
