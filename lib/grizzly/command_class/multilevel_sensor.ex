defmodule Grizzly.CommandClass.MultilevelSensor do
  @moduledoc """
    Conversions for multilevel sensors.
  """

  @type level_type :: :temperature | :illuminance | :power | :humidity
  @sensor_types [
    # byte 1
    [
      :air_temperature,
      :general_purpose,
      :illuminance,
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

  @spec decode_type(byte) :: level_type | byte
  def decode_type(type_num) do
    case type_num do
      1 -> :temperature
      3 -> :illuminance
      4 -> :power
      5 -> :humidity
      other -> other
    end
  end

  @spec encode_type(level_type) :: 1 | 3 | 4 | 5
  def encode_type(type) do
    case type do
      :temperature -> 0x1
      :illuminance -> 0x3
      :power -> 0x4
      :humidity -> 0x5
    end
  end

  @spec decode_sensor_types(binary) :: [:atom]
  def decode_sensor_types(binary) do
    :binary.bin_to_list(binary)
    |> Enum.map(&bit_set_indices(<<&1>>))
    |> Enum.with_index()
    |> Enum.map(fn {bit_indices, byte} -> Enum.map(bit_indices, &decode_sensor(byte, &1)) end)
    |> List.flatten()
  end

  defp bit_set_indices(byte) do
    for(<<x::1 <- byte>>, do: x)
    |> Enum.with_index()
    |> Enum.reduce([], fn {bit, index}, acc ->
      if bit == 1, do: [index | acc], else: acc
    end)
  end

  defp decode_sensor(byte, bit_index) do
    Enum.at(@sensor_types, byte) |> Enum.at(bit_index)
  end
end
