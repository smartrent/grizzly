defmodule Grizzly.ZWave.CommandClasses.SensorMultilevel do
  @moduledoc """
  "SensorMultilevel" Command Class

  The Multilevel Sensor Command Class is used to advertise numerical sensor readings.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @sensor_types [
    # byte 1
    [
      :air_temperature,
      :general_purpose,
      :luminance,
      :power,
      :humidity,
      :velocity,
      :direction,
      :atmospheric_pressure
    ],
    # byte 2
    [
      :barometric_pressure,
      :solar_radiation,
      :dew_point,
      :rain_rate,
      :tide_level,
      :weight,
      :voltage,
      :current
    ],
    # byte 3
    [
      :carbon_dioxide_level,
      :air_flow,
      :tank_capacity,
      :distance,
      :angle_position,
      :rotation,
      :water_temperature,
      :soil_temperature
    ],
    # byte 4
    [
      :seismic_intensity,
      :seismic_magnitude,
      :ultraviolet,
      :electrical_resistivity,
      :electrical_conductivity,
      :loudness,
      :moisture,
      :frequency
    ],
    # byte 5
    [
      :time,
      :target_temperature,
      :particulate_matter_2_5,
      :formaldehyde_level,
      :radon_concentration,
      :methane_density,
      :volatile_organic_compound_level,
      :carbon_monoxide_level
    ],
    # byte 6
    [
      :soil_humidity,
      :soil_reactivity,
      :soil_salinity,
      :heart_rate,
      :blood_pressure,
      :muscle_mass,
      :fat_mass,
      :bone_mass
    ],
    # byte 7
    [
      :total_body_water,
      :basis_metabolic_rate,
      :body_mass_index,
      :acceleration_x_axis,
      :acceleration_y_axis,
      :acceleration_z_axis,
      :smoke_density,
      :water_flow
    ],
    # byte 8
    [
      :water_pressure,
      :rf_signal_strength,
      :particulate_matter_10,
      :respiratory_rate,
      :relative_modulation_level,
      :boiler_water_temperature,
      :domestic_hot_water_temperature,
      :outside_temperature
    ],
    # byte 9
    [
      :exhaust_temperature,
      :water_chlorine_level,
      :water_acidity,
      :water_oxidation_reduction_potential,
      :heart_rate_lf_hf_ratio,
      :motion_direction,
      :applied_force,
      :return_air_temperature
    ],
    # byte 10
    [
      :supply_air_temperature,
      :condensor_coil_temperature,
      :evaporator_coil_temperature,
      :liquid_line_temperature,
      :discharge_line_temperature,
      :suction_pressure,
      :discharge_pressure,
      :defrost_temperature
    ],
    # byte 11
    [
      :ozone,
      :sulfur_dioxide,
      :nitrogen_dioxide,
      :ammonia,
      :lead,
      :particulate_matter_1,
      :unknown,
      :unknown
    ]
  ]

  @impl true
  def byte(), do: 0x31

  @impl true
  def name(), do: :sensor_multilevel

  def encode_sensor_type(:temperature), do: 0x01
  def encode_sensor_type(:general), do: 0x02
  def encode_sensor_type(:luminance), do: 0x03
  def encode_sensor_type(:power), do: 0x04
  def encode_sensor_type(:humidity), do: 0x05
  def encode_sensor_type(:velocity), do: 0x06
  def encode_sensor_type(:direction), do: 0x07
  def encode_sensor_type(:atmospheric_pressure), do: 0x08
  def encode_sensor_type(:barometric_pressure), do: 0x09
  def encode_sensor_type(:solar_radiation), do: 0x0A
  def encode_sensor_type(:dew_point), do: 0x0B
  def encode_sensor_type(:rain_rate), do: 0x0C
  def encode_sensor_type(:tide_level), do: 0x0D
  def encode_sensor_type(:weight), do: 0x0E
  def encode_sensor_type(:voltage), do: 0x0F
  def encode_sensor_type(:current), do: 0x10
  def encode_sensor_type(:co2_level), do: 0x11
  def encode_sensor_type(:air_flow), do: 0x12
  def encode_sensor_type(:tank_capacity), do: 0x13
  def encode_sensor_type(:distance), do: 0x14
  def encode_sensor_type(:angle_position), do: 0x15
  def encode_sensor_type(:rotation), do: 0x16
  def encode_sensor_type(:water_temperature), do: 0x17
  def encode_sensor_type(:soil_temperature), do: 0x18
  def encode_sensor_type(:seismic_intensity), do: 0x19
  def encode_sensor_type(:seismic_magnitude), do: 0x1A
  def encode_sensor_type(:ultraviolet), do: 0x1B
  def encode_sensor_type(:electrical_resistivity), do: 0x1C
  def encode_sensor_type(:electrical_conductivity), do: 0x1D
  def encode_sensor_type(:loudness), do: 0x1E
  def encode_sensor_type(:moisture), do: 0x1F
  def encode_sensor_type(:frequency), do: 0x20
  def encode_sensor_type(:time), do: 0x21
  def encode_sensor_type(:target_temperature), do: 0x22

  def decode_sensor_type(0x01), do: {:ok, :temperature}
  def decode_sensor_type(0x02), do: {:ok, :general}
  def decode_sensor_type(0x03), do: {:ok, :luminance}
  def decode_sensor_type(0x04), do: {:ok, :power}
  def decode_sensor_type(0x05), do: {:ok, :humidity}
  def decode_sensor_type(0x06), do: {:ok, :velocity}
  def decode_sensor_type(0x07), do: {:ok, :direction}
  def decode_sensor_type(0x08), do: {:ok, :atmospheric_pressure}
  def decode_sensor_type(0x09), do: {:ok, :barometric_pressure}
  def decode_sensor_type(0x0A), do: {:ok, :solar_radiation}
  def decode_sensor_type(0x0B), do: {:ok, :dew_point}
  def decode_sensor_type(0x0C), do: {:ok, :rain_rate}
  def decode_sensor_type(0x0D), do: {:ok, :tide_level}
  def decode_sensor_type(0x0E), do: {:ok, :weight}
  def decode_sensor_type(0x0F), do: {:ok, :voltage}
  def decode_sensor_type(0x10), do: {:ok, :current}
  def decode_sensor_type(0x11), do: {:ok, :co2_level}
  def decode_sensor_type(0x12), do: {:ok, :air_flow}
  def decode_sensor_type(0x13), do: {:ok, :tank_capacity}
  def decode_sensor_type(0x14), do: {:ok, :distance}
  def decode_sensor_type(0x15), do: {:ok, :angle_position}
  def decode_sensor_type(0x16), do: {:ok, :rotation}
  def decode_sensor_type(0x17), do: {:ok, :water_temperature}
  def decode_sensor_type(0x18), do: {:ok, :soil_temperature}
  def decode_sensor_type(0x19), do: {:ok, :seismic_intensity}
  def decode_sensor_type(0x1A), do: {:ok, :seismic_magnitude}
  def decode_sensor_type(0x1B), do: {:ok, :ultraviolet}
  def decode_sensor_type(0x1C), do: {:ok, :electrical_resistivity}
  def decode_sensor_type(0x1D), do: {:ok, :electrical_conductivity}
  def decode_sensor_type(0x1E), do: {:ok, :loudness}
  def decode_sensor_type(0x1F), do: {:ok, :moisture}
  def decode_sensor_type(0x20), do: {:ok, :frequency}
  def decode_sensor_type(0x21), do: {:ok, :time}
  def decode_sensor_type(0x22), do: {:ok, :target_temperature}

  def decode_sensor_type(byte),
    do:
      {:error, %DecodeError{value: byte, param: :sensor_type, command: :sensor_multilevel_report}}

  @spec decode_sensor_types(binary) :: {:ok, [sensor_types: [atom]]} | {:error, DecodeError.t()}
  def decode_sensor_types(binary) do
    sensor_types =
      :binary.bin_to_list(binary)
      |> Enum.map(&bit_set_indices(<<&1>>))
      |> Enum.with_index()
      |> Enum.map(fn {bit_indices, byte} -> Enum.map(bit_indices, &decode_sensor(byte, &1)) end)
      |> List.flatten()

    if Enum.any?(sensor_types, &(&1 == nil)) do
      {:error,
       %DecodeError{
         value: binary,
         param: :sensor_types,
         command: :sensor_multilevel_supported_sensor_report
       }}
    else
      {:ok, [sensor_types: sensor_types]}
    end
  end

  @spec encode_sensor_types([atom]) :: binary
  def encode_sensor_types(sensor_types) do
    for bit_list <- byte_indices(sensor_types) do
      for bit <- Enum.reverse(bit_list), into: <<>>, do: <<bit::1>>
    end
    |> :binary.list_to_bin()
  end

  defp byte_indices(sensor_types) do
    for byte <- (Enum.count(@sensor_types) - 1)..0 do
      sensor_types_per_byte = Enum.at(@sensor_types, byte)

      for index <- 0..7 do
        if Enum.at(sensor_types_per_byte, index) in sensor_types, do: 1, else: 0
      end
    end
    |> Enum.drop_while(fn indices -> Enum.all?(indices, &(&1 == 0)) end)
    |> Enum.reverse()
  end

  defp bit_set_indices(byte) do
    for(<<x::1 <- byte>>, do: x)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce([], fn {bit, index}, acc ->
      if bit == 1, do: [index | acc], else: acc
    end)
  end

  defp decode_sensor(byte, bit_index) do
    Enum.at(@sensor_types, byte) |> Enum.at(bit_index)
  end
end
