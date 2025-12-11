## 🔍 Project Overview – I2C VGA Image Processing System

- **카메라 입력:** OV7670 영상 데이터 캡처  
- **VGA Controller:**  
  - 640×480 영상 출력  
  - 프레임 버퍼 기반 RGB444 변환  
- **Image Processing:**  
  - Sobel Edge, Gaussian Blur, Retro, Morphology, Cartoon Filter  
  - 실시간 Line Buffer 기반 필터링  
- **Mini Game:**  
  - LT/RT/LB/RB 4-way 영역 감지  
  - Color Detector 기반 실시간 PASS/FAIL 판정  
  - FSM 기반 게임 흐름 제어  
- **Troubleshooting:**  
  - Chroma Key LUT 증가로 인한 Logic Overflow 문제 해결  
  - BRAM 사용량 증가 원인 분석 및 최적화  
- **Demo:**  
  - 실시간 필터 출력  
  - 미니게임 스코어 및 결과 표시

## 📄 I2C VGA Image Processing & Mini Game Project (PDF Report)

전체 프로젝트 문서(PDF)는 아래 링크에서 확인할 수 있습니다.

👉 [📘 **I2C_VGA 프로젝트 보고서 PDF 열기**](./I2C_VGA.pdf)


:contentReference[oaicite:0]{index=0}

---

### 📌 PDF 미리보기 썸네일 (옵션)

아래 이미지를 클릭하면 PDF가 열립니다:

[![PDF Preview](./i2c_vga_page1.png)](./I2C_VGA.pdf)

