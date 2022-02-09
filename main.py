
#arcgis_sdk pyqt5/qt 
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.QtWidgets import *

from denemeui import Ui_MainWindow

import os
from PyQt5.QtQuick import QQuickView
import threading
import time
import dronekit
from geographiclib.geodesic import Geodesic

geod = Geodesic.WGS84
class MainWindow(QMainWindow):
	def __init__(self):
		QMainWindow.__init__(self) #MainWindow inheritance
		self.ui = Ui_MainWindow() #Main Ui 
		self.ui.setupUi(self)
		self.sayac = 0
		self.const=180/3.14
		self.yaw = 0
		self.lat, self.lon = 39,32
		self.lastLat, self.lastLon = 39,32 
		self.droneYaw, self.dronePitch, self.droneYaw, self.elevation = 0,0,0,0
		# threading.Thread(target=self.updateMarker, daemon = True).start()
		# threading.Thread(target=self.connectDrone, daemon = True).start()
		self.showMaximized()

	def addHudMap(self, view):
		qml_file = os.path.join(os.path.dirname(__file__), "Animate3DSymbols.qml")
		view.setSource(QUrl.fromLocalFile(os.path.abspath(qml_file)))
		widget = QWidget.createWindowContainer(view)
		self.ui.gridLayout.addWidget(widget)
		self.objectName = view.findChild(QObject, "hudBarCompenets")


	def add_map(self, map_gis):
		if map_gis.mode == "2D":
			print("Zoom =\t\t{}\n".format(map_gis.zoom) + \
				"Rotation =\t{}".format(map_gis.rotation))
		elif map_gis.mode == "3D":
			print("Zoom =\t\t{}\n".format(map_gis.zoom) + \
				"Tilt =\t\t{}\n".format(map_gis.tilt) + \
				"Heading =\t{}".format(map_gis.heading))
		else:
			raise Exception("Not supported argument")

	def updateMarker(self):
		time.sleep(3)
		self.objectName.setProperty("elevation2",1000)
		while True:
			try:
				############ Smooth #############
				# self.sayac += 1.2
				# coord = geod.Direct(self.lastLat,self.lastLon, self.yaw, self.sayac)
				# self.objectName.setProperty("lat2",coord['lat2'])
				# self.objectName.setProperty("lon2",coord['lon2'])
				#################################

				self.objectName.setProperty("roll2", self.droneRoll)
				self.objectName.setProperty("yaw2", self.droneYaw)
				self.objectName.setProperty("pitch2",self.dronePitch)
				self.objectName.setProperty("elevation2",self.elevation)

				self.objectName.setProperty("lat2",self.lat)
				self.objectName.setProperty("lon2",self.lon)
			except:
				pass
			time.sleep(0.1)

	def connectDrone(self):
		drone = dronekit.connect('tcp:127.0.0.1:5763', wait_ready=True, baud=57600)
		print("connect")
		while True:
			self.lat = drone.location.global_relative_frame.lat
			self.lon = drone.location.global_relative_frame.lon
			self.droneYaw = (drone.attitude.yaw*self.const)%360
			self.droneRoll = (drone.attitude.roll*self.const)%360
			self.dronePitch = (drone.attitude.pitch*self.const)%360
			self.elevation = drone.location.global_frame.alt
			self.smooth(self.lat, self.lon)
			time.sleep(0.01)
		
	def smooth(self, lat, lon):
		self.yaw = geod.Inverse(self.lastLat, self.lastLon, lat, lon)['azi1']
		self.lastLat, self.lastLon = lat, lon
		self.sayac = 0


if __name__ == "__main__":
	import sys
	app = QApplication(sys.argv)
	window = MainWindow()
	view = QQuickView(resizeMode=QQuickView.SizeRootObjectToView)
	window.addHudMap(view)
	sys.exit(app.exec_())
