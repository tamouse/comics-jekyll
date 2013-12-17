require 'pathname'
ROOT ||= Pathname.pwd
APP = ROOT.basename.to_s
LOGDIR = ROOT + "log"
LOGFILENAME = LOGDIR + "#{APP.to_s}.log"

require 'fileutils'
FileUtils.mkdir_p(LOGDIR.to_s)

require 'log4r'
require 'log4r/outputter/iooutputter'
require 'log4r/formatter/patternformatter'

Log4r::Logger.root.level = Log4r::DEBUG
Log = Log4r::Logger.new(APP.to_s)
Log.trace = true
Log.add Log4r::IOOutputter.new('stdout',
                               $stdout,
                               :formatter => Log4r::PatternFormatter.new(:pattern => "%m"))
Log.add Log4r::FileOutputter.new(APP,
                                 :filename => LOGFILENAME.to_s,
                                 :formatter => Log4r::PatternFormatter.new(:pattern => "%d %-6l %m (%t)"))
