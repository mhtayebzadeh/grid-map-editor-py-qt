import math
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer

class RobotHandler(QObject):
    poseChanged = Signal(float, float, float) # x, y, theta
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._x = 0.0
        self._y = 0.0
        self._theta = 0.0
        
        # Simulating robot movement
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._fake_update)
        self._timer.start(100) # 10Hz update
        
    @Property(float, notify=poseChanged)
    def x(self):
        return self._x
        
    @Property(float, notify=poseChanged)
    def y(self):
        return self._y
        
    @Property(float, notify=poseChanged)
    def theta(self):
        return self._theta
        
    def _fake_update(self):
        # Move in a circle
        self._theta += 0.05
        if self._theta > math.pi * 2:
            self._theta -= math.pi * 2
            
        radius = 1.0
        # Just update x, y based on some fake logic, let's say it moves slowly
        self._x += math.cos(self._theta) * 0.02
        self._y += math.sin(self._theta) * 0.02
        self.poseChanged.emit(self._x, self._y, self._theta)

