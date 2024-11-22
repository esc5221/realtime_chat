const Draggable = {
  mounted() {
    if (this.el.dataset.draggable !== "true") return;

    this.el.addEventListener('mousedown', e => {
      if (e.target.closest('.message-history')) return;
      
      const rect = this.el.getBoundingClientRect();
      const offsetX = e.clientX - rect.left;
      const offsetY = e.clientY - rect.top;

      const onMouseMove = e => {
        const x = e.clientX - offsetX;
        const y = e.clientY - offsetY;
        
        // 캔버스 경계 확인
        const canvas = document.querySelector('.canvas-container');
        const canvasRect = canvas.getBoundingClientRect();
        const boxRect = this.el.getBoundingClientRect();
        
        const boundedX = Math.max(0, Math.min(x, canvasRect.width - boxRect.width));
        const boundedY = Math.max(0, Math.min(y, canvasRect.height - boxRect.height));

        this.el.style.left = `${boundedX}px`;
        this.el.style.top = `${boundedY}px`;
        
        this.pushEvent("update_position", { x: boundedX, y: boundedY });
      };

      const onMouseUp = () => {
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
        this.pushEvent("end_drag");
      };

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
      this.pushEvent("start_drag");
    });

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
    // 캔버스 초기화 로직이 필요한 경우 여기에 추가
  }
};

export default { Draggable, ChatCanvas };
