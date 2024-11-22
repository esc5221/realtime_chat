const ChatCanvas = {
  mounted() {
    let scale = 1;
    let translateX = 0;
    let translateY = 0;
    let startX = 0;
    let startY = 0;
    let lastDistance = 0;

    const updateTransform = () => {
      this.el.style.transform = `scale(${scale}) translate(${translateX}px, ${translateY}px)`;
      // 모든 채팅 박스에 scale 정보 전달
      document.querySelectorAll('.user-chat-box').forEach(box => {
        box.dataset.canvasScale = scale;
      });
    };

    const onWheel = (e) => {
      e.preventDefault();
      const delta = e.deltaY * -0.01;
      const newScale = Math.min(Math.max(0.5, scale + delta), 2);
      
      if (newScale !== scale) {
        // 줌의 중심점을 마우스 위치로 설정
        const rect = this.el.getBoundingClientRect();
        const mouseX = (e.clientX - rect.left) / scale;
        const mouseY = (e.clientY - rect.top) / scale;
        
        const newTranslateX = mouseX - (mouseX - translateX) * (newScale / scale);
        const newTranslateY = mouseY - (mouseY - translateY) * (newScale / scale);
        
        scale = newScale;
        translateX = newTranslateX;
        translateY = newTranslateY;
        
        updateTransform();
      }
    };

    const onTouchStart = (e) => {
      if (e.touches.length === 2) {
        const touch1 = e.touches[0];
        const touch2 = e.touches[1];
        lastDistance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );
      } else if (e.touches.length === 1) {
        const touch = e.touches[0];
        startX = touch.clientX - translateX * scale;
        startY = touch.clientY - translateY * scale;
      }
    };

    const onTouchMove = (e) => {
      e.preventDefault();
      if (e.touches.length === 2) {
        const touch1 = e.touches[0];
        const touch2 = e.touches[1];
        const distance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );

        const delta = (distance - lastDistance) * 0.01;
        const newScale = Math.min(Math.max(0.5, scale + delta), 2);
        
        if (newScale !== scale) {
          // 줌의 중심점을 두 손가락 중앙으로 설정
          const centerX = (touch1.clientX + touch2.clientX) / 2;
          const centerY = (touch1.clientY + touch2.clientY) / 2;
          const rect = this.el.getBoundingClientRect();
          const mouseX = (centerX - rect.left) / scale;
          const mouseY = (centerY - rect.top) / scale;
          
          const newTranslateX = mouseX - (mouseX - translateX) * (newScale / scale);
          const newTranslateY = mouseY - (mouseY - translateY) * (newScale / scale);
          
          scale = newScale;
          translateX = newTranslateX;
          translateY = newTranslateY;
          
          updateTransform();
        }
        
        lastDistance = distance;
      } else if (e.touches.length === 1) {
        const touch = e.touches[0];
        translateX = (touch.clientX - startX) / scale;
        translateY = (touch.clientY - startY) / scale;
        updateTransform();
      }
    };

    this.el.addEventListener('wheel', onWheel, { passive: false });
    this.el.addEventListener('touchstart', onTouchStart, { passive: true });
    this.el.addEventListener('touchmove', onTouchMove, { passive: false });
  }
};

const Draggable = {
  mounted() {
    if (this.el.dataset.draggable !== "true") return;

    let isDragging = false;
    let startX, startY;
    let lastUpdate = 0;
    let currentX = 0;
    let currentY = 0;
    let initialTouchDistance = 0;
    const serverUpdateInterval = 100;
    const MIN_DISTANCE = 100;
    const DRAG_THRESHOLD = 5;

    const getCanvasScale = () => {
      return parseFloat(this.el.dataset.canvasScale || "1");
    };

    const getComponentCenter = (element) => {
      const rect = element.getBoundingClientRect();
      return {
        x: rect.left + rect.width / 2,
        y: rect.top + rect.height / 2
      };
    };

    const distance = (p1, p2) => {
      return Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));
    };

    const isWithinComponent = (x, y) => {
      const rect = this.el.getBoundingClientRect();
      return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
    };

    const resolveCollision = (newX, newY) => {
      const scale = getCanvasScale();
      const currentComponent = this.el;
      const currentCenter = getComponentCenter(currentComponent);
      let minAdjustment = { x: 0, y: 0 };
      let hasCollision = false;

      document.querySelectorAll('.user-chat-box').forEach(otherComponent => {
        if (otherComponent === currentComponent) return;

        const otherCenter = getComponentCenter(otherComponent);
        const dist = distance(currentCenter, otherCenter);

        if (dist < MIN_DISTANCE) {
          hasCollision = true;
          const angle = Math.atan2(currentCenter.y - otherCenter.y, currentCenter.x - otherCenter.x);
          const pushDistance = MIN_DISTANCE - dist;
          
          const adjustX = Math.cos(angle) * pushDistance;
          const adjustY = Math.sin(angle) * pushDistance;

          if (Math.abs(adjustX) > Math.abs(minAdjustment.x)) minAdjustment.x = adjustX;
          if (Math.abs(adjustY) > Math.abs(minAdjustment.y)) minAdjustment.y = adjustY;
        }
      });

      if (hasCollision) {
        return {
          x: newX + minAdjustment.x / scale,
          y: newY + minAdjustment.y / scale
        };
      }

      return { x: newX, y: newY };
    };

    const updateVisualPosition = (x, y, skipCollision = false) => {
      const newPos = skipCollision ? { x, y } : resolveCollision(x, y);
      currentX = newPos.x;
      currentY = newPos.y;
      
      requestAnimationFrame(() => {
        const scale = getCanvasScale();
        this.el.style.transform = `translate3d(${newPos.x * scale}px, ${newPos.y * scale}px, 0)`;
      });
    };

    const updateServerPosition = () => {
      const now = Date.now();
      if (now - lastUpdate >= serverUpdateInterval) {
        this.pushEvent("update_position", { 
          x: Math.round(currentX), 
          y: Math.round(currentY) 
        });
        lastUpdate = now;
      }
    };

    // 마우스 이벤트 핸들러
    const onMouseDown = (e) => {
      if (e.button !== 0 || !isWithinComponent(e.clientX, e.clientY)) return;
      if (e.target.closest('.message-history')) return;
      
      e.preventDefault();
      e.stopPropagation();
      
      isDragging = true;
      const scale = getCanvasScale();
      startX = e.clientX - currentX * scale;
      startY = e.clientY - currentY * scale;
      
      this.el.style.cursor = 'grabbing';
      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    };

    const onMouseMove = (e) => {
      if (!isDragging) return;
      
      e.preventDefault();
      e.stopPropagation();
      
      const scale = getCanvasScale();
      const newX = (e.clientX - startX) / scale;
      const newY = (e.clientY - startY) / scale;
      
      updateVisualPosition(newX, newY);
      updateServerPosition();
    };

    const onMouseUp = (e) => {
      if (!isDragging) return;
      
      e.preventDefault();
      e.stopPropagation();
      
      isDragging = false;
      this.el.style.cursor = 'grab';
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };

    // 터치 이벤트 핸들러
    const onTouchStart = (e) => {
      if (e.touches.length !== 1) return;
      if (e.target.closest('.message-history')) return;

      const touch = e.touches[0];
      if (!isWithinComponent(touch.clientX, touch.clientY)) return;

      e.preventDefault();
      e.stopPropagation();

      isDragging = true;
      const scale = getCanvasScale();
      startX = touch.clientX - currentX * scale;
      startY = touch.clientY - currentY * scale;
      initialTouchDistance = 0;
    };

    const onTouchMove = (e) => {
      if (!isDragging || e.touches.length !== 1) return;

      e.preventDefault();
      e.stopPropagation();

      const touch = e.touches[0];
      const scale = getCanvasScale();
      
      if (initialTouchDistance === 0) {
        const dx = touch.clientX - startX;
        const dy = touch.clientY - startY;
        initialTouchDistance = Math.sqrt(dx * dx + dy * dy);
        if (initialTouchDistance < DRAG_THRESHOLD) return;
      }

      const newX = (touch.clientX - startX) / scale;
      const newY = (touch.clientY - startY) / scale;
      
      updateVisualPosition(newX, newY);
      updateServerPosition();
    };

    const onTouchEnd = (e) => {
      if (!isDragging) return;
      
      e.preventDefault();
      e.stopPropagation();
      
      isDragging = false;
      initialTouchDistance = 0;
    };

    // 이벤트 리스너 등록
    this.el.style.cursor = 'grab';
    this.el.addEventListener('mousedown', onMouseDown);
    this.el.addEventListener('touchstart', onTouchStart, { passive: false });
    this.el.addEventListener('touchmove', onTouchMove, { passive: false });
    this.el.addEventListener('touchend', onTouchEnd);

    // 컴포넌트 제거 시 이벤트 리스너 정리
    this.destroy = () => {
      this.el.removeEventListener('mousedown', onMouseDown);
      this.el.removeEventListener('touchstart', onTouchStart);
      this.el.removeEventListener('touchmove', onTouchMove);
      this.el.removeEventListener('touchend', onTouchEnd);
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };
  }
};

export default { Draggable, ChatCanvas };
