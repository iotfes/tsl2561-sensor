#!/usr/bin/ruby
require 'i2c' # http://rubydoc.info/gems/i2c/0.2.22/I2C/Dev

class LightSensor
	# Lightsensor: TAOS TSL2561
	DEV_ADDR = 0x39
	# registers
        REG_CONTROL = 0x00
        REG_TIMING = 0x01
        REG_THRESHLOWLOW = 0x02
        REG_THRESHLOWHIGH = 0x03
        REG_THRESHHIGHLOW = 0x04
        REG_THRESHHIGHHIGH = 0x05
        REG_INTERRUPT = 0x06
        REG_DATA0LOW = 0x0C
        REG_DATA0HIGH = 0x0D
        REG_DATA1LOW = 0x0E
        REG_DATA1HIGH = 0x0F
        # command register
        VAL_CMD_SELECT = 0x08
        VAL_CMD_CLEAR = 0x04
        VAL_CMD_WORD = 0x02
        VAL_CMD_BLOCK = 0x01
        # control register
        VAL_CTRL_ON = 0x03
        VAL_CTRL_OFF = 0x00
	class Luminosity
		class Channel
			attr_accessor :val
		end
		# channel0: visible & infrared light
		# channel1: infrared light
		attr_accessor :channel0, :channel1
		def calcLux
			if @channel0 > 0
				if (@channel1/@channel0).between?(0.0, 0.52)
					return (0.0315*@channel0)-(0.0593*@channel0*((@channel1/@channel0)**1.4))
				elsif (@channel1/@channel0).between?(0.52, 0.65)
					return (0.0229*@channel0)-(0.0291*@channel1)
				elsif (@channel1/@channel0).between?(0.65, 0.80)
					return (0.0157*@channel0)-(0.0180*@channel1)
				elsif (@channel1/@channel0).between?(0.80, 1.30)
					return (0.00338*@channel0)-(0.00260*@channel1)
				elsif @channel1/@channel0 > 1.30
					return 0
				end
			else
				return 0
			end
		end
	end
	def initialize(bus)
		@bus = I2C.create(bus)
	end
	def turnOn
		@bus.write(DEV_ADDR, REG_CONTROL, VAL_CTRL_ON)
	end
	def turnOff
		@bus.write(DEV_ADDR, REG_CONTROL, VAL_CTRL_OFF)
	end
	def getLuminosity
		# default conversion time is 402 ms, so make sure you wait this time after each measure
		l = Luminosity.new
		l.channel0 = @bus.read(DEV_ADDR, 2, ((VAL_CMD_SELECT ^ VAL_CMD_WORD) << 4) ^ REG_DATA0LOW).unpack('S').first
		l.channel1 = @bus.read(DEV_ADDR, 2, ((VAL_CMD_SELECT ^ VAL_CMD_WORD) << 4) ^ REG_DATA1LOW).unpack('S').first
		return l
	end
end

