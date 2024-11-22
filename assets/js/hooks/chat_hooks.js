const Draggable = {
  mounted() {
    if (this.el.dataset.draggable !== "true") return;

    let isDragging = false;
    let startX, startY;
    let lastUpdate = 0;
    let currentX = 0;
    let currentY = 0;
    const serverUpdateInterval = 100; // 서버 업데이트는 100ms 간격

    const updateVisualPosition = (x, y) => {
      currentX = x;
      currentY = y;
      // 시각적 업데이트는 즉시 실행
      this.el.style.transform = `translate3d(${x}px, ${y}px, 0)`;
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

    const onMouseDown = (e) => {
      if (e.target.closest('.message-history')) return;
      
      isDragging = true;
      const rect = this.el.getBoundingClientRect();
      startX = e.clientX - rect.left;
      startY = e.clientY - rect.top;

      // 드래그 최적화
      this.el.style.willChange = 'transform';
      document.body.style.cursor = 'grabbing';
      this.el.style.transition = 'none'; // 드래그 중에는 트랜지션 제거

      document.addEventListener('mousemove', onMouseMove, { passive: true });
      document.addEventListener('mouseup', onMouseUp);
    };

    const onMouseMove = (e) => {
      if (!isDragging) return;

      requestAnimationFrame(() => {
        const canvas = document.getElementById('chat-canvas');
        const canvasRect = canvas.getBoundingClientRect();
        
        let x = e.clientX - startX - canvasRect.left;
        let y = e.clientY - startY - canvasRect.top;
        
        // 캔버스 경계 확인
        const boxWidth = this.el.offsetWidth;
        const boxHeight = this.el.offsetHeight;
        
        x = Math.max(0, Math.min(x, canvasRect.width - boxWidth));
        y = Math.max(0, Math.min(y, canvasRect.height - boxHeight));

        // 시각적 업데이트는 즉시
        updateVisualPosition(x, y);
        // 서버 업데이트는 쓰로틀링
        updateServerPosition();
      });
    };

    const onMouseUp = () => {
      if (!isDragging) return;
      isDragging = false;

      // 최적화 스타일 제거
      this.el.style.willChange = 'auto';
      this.el.style.transition = ''; // 트랜지션 복원
      document.body.style.cursor = 'default';

      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);

      // 마지막 위치는 즉시 서버에 전송
      this.pushEvent("update_position", { 
        x: Math.round(currentX), 
        y: Math.round(currentY) 
      });
    };

    this.el.addEventListener('mousedown', onMouseDown);

    // 메시지 히스토리 호버 기능
    const messageHistory = this.el.querySelector('.message-history');
    if (messageHistory) {
      this.el.addEventListener('mouseenter', () => {
        messageHistory.classList.remove('hidden');
      });
      
      this.el.addEventListener('mouseleave', () => {
        messageHistory.classList.add('hidden');
      });
    }
  }
};

const ChatCanvas = {
  mounted() {
    console.log('ChatCanvas mounted');
  }
};

export default { Draggable, ChatCanvas };
