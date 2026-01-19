kakao.maps.load(function() {
    const mapContainer = document.getElementById('map');
    const mapOption = {
        center: new kakao.maps.LatLng(37.8813, 127.7300), // 춘천시청 좌표
        level: 5 // 강원도 지역을 고려하여 조금 더 넓게 표시
    };

    const map = new kakao.maps.Map(mapContainer, mapOption);

    // 계층형 지역 메뉴 생성 함수
    const cityBtnContainer = document.getElementById('city-buttons');
    
    function createRegionTree(container, data) {
        data.forEach(region => {
            const itemDiv = document.createElement('div');
            itemDiv.className = 'region-item';

            const headerDiv = document.createElement('div');
            headerDiv.className = 'region-header';

            // 토글 버튼 (+/-)
            const toggleBtn = document.createElement('span');
            toggleBtn.className = 'toggle-btn';
            const hasChildren = region.children && region.children.length > 0;
            
            if (hasChildren) {
                toggleBtn.innerText = '+';
            } else {
                toggleBtn.innerText = '•'; // 하위 항목 없으면 점 표시
                toggleBtn.style.color = '#ccc';
                toggleBtn.style.cursor = 'default';
            }
            headerDiv.appendChild(toggleBtn);

            // 지역 이름 (클릭 시 이동)
            const nameSpan = document.createElement('span');
            nameSpan.className = 'region-name';
            nameSpan.innerText = region.name;
            nameSpan.onclick = function() {
                const moveLatLon = new kakao.maps.LatLng(region.lat, region.lng);
                const zoomLevel = region.level || 5;
                map.setLevel(zoomLevel);
                map.panTo(moveLatLon);
            };
            headerDiv.appendChild(nameSpan);

            itemDiv.appendChild(headerDiv);

            // 하위 목록 컨테이너
            if (hasChildren) {
                const subContainer = document.createElement('div');
                subContainer.className = 'sub-regions';
                createRegionTree(subContainer, region.children);
                itemDiv.appendChild(subContainer);

                // 토글 이벤트
                toggleBtn.onclick = function() {
                    const isOpen = subContainer.classList.contains('open');
                    subContainer.classList.toggle('open');
                    toggleBtn.innerText = isOpen ? '+' : '-';
                };
            }
            container.appendChild(itemDiv);
        });
    }

    // 현재 열려있는 인포윈도우를 추적하기 위한 변수
    let activeInfoWindow = null;

    // 사이드바 토글 함수
    window.toggleSidebar = function(side) {
        const sidebar = document.getElementById(side + 'Sidebar');
        const btn = document.getElementById('btn-open-' + side);
        
        if (sidebar.classList.contains('collapsed')) {
            sidebar.classList.remove('collapsed');
            btn.style.display = 'none';
            localStorage.setItem(side + 'SidebarState', 'open');
        } else {
            sidebar.classList.add('collapsed');
            btn.style.display = 'block';
            localStorage.setItem(side + 'SidebarState', 'closed');
        }
        // 사이드바 변경 후 지도 크기 재계산
        setTimeout(() => map.relayout(), 300);
    };

    // 페이지 로드 시 저장된 사이드바 상태 복원
    (function restoreSidebarState() {
        ['left', 'right'].forEach(side => {
            const state = localStorage.getItem(side + 'SidebarState');
            if (state === 'closed') {
                const sidebar = document.getElementById(side + 'Sidebar');
                const btn = document.getElementById('btn-open-' + side);
                sidebar.classList.add('collapsed');
                btn.style.display = 'block';
            }
        });
        setTimeout(() => map.relayout(), 100);
    })();

    // 그룹 ID를 기반으로 고유한 색상을 생성하는 함수 (반경 표시용)
    function getGroupColorById(id) {
        let hash = 0;
        for (let i = 0; i < id.length; i++) {
            hash = id.charCodeAt(i) + ((hash << 5) - hash);
        }
        const h = Math.abs(hash % 360);
        return { stroke: `hsl(${h}, 70%, 45%)`, fill: `hsl(${h}, 90%, 85%)` };
    }

    // 상태에 따라 핀 색상을 반환하는 함수 (마커 표시용)
    function getStatusColor(status) {
        switch (status) {
            case '접수됨': return '#dc3545'; // 빨강
            case '처리중': return '#fd7e14'; // 주황
            case '완료': return '#198754'; // 초록
            case '포트홀아님': return '#6c757d'; // 회색
            default: return '#0d6efd'; // 파랑
        }
    }

    // 전역 변수로 지역 데이터 저장
    let regionData = [];

    // 거리 계산 함수 (Haversine formula)
    function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
        const R = 6371; 
        const dLat = (lat2 - lat1) * (Math.PI / 180);
        const dLon = (lon2 - lon1) * (Math.PI / 180);
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                  Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
                  Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    // 좌표로 지역 찾기 함수
    function getRegionFromCoords(lat, lng) {
        if (!regionData || regionData.length === 0) return "";
        let minDistance = Infinity;
        let closestCity = null;
        regionData.forEach(city => {
            const dist = getDistanceFromLatLonInKm(lat, lng, city.lat, city.lng);
            if (dist < minDistance) { minDistance = dist; closestCity = city; }
        });
        if (!closestCity) return "";
        let regionName = closestCity.name;
        if (closestCity.children && closestCity.children.length > 0) {
            let minSubDistance = Infinity;
            let closestSubObj = null;
            closestCity.children.forEach(sub => {
                const subDist = getDistanceFromLatLonInKm(lat, lng, sub.lat, sub.lng);
                if (subDist < minSubDistance) { minSubDistance = subDist; closestSubObj = sub; }
            });
            if (closestSubObj && minSubDistance < 50) { regionName += " " + closestSubObj.name; }
        }
        return regionName;
    }

    // 지역 이름으로 색상 생성
    function getRegionColor(name) {
        if (!name) return '#6c757d';
        const city = name.split(' ')[0];
        let hash = 0;
        for (let i = 0; i < city.length; i++) { hash = city.charCodeAt(i) + ((hash << 5) - hash); }
        const h = Math.abs(hash % 360);
        return `hsl(${h}, 65%, 40%)`;
    }

    // 데이터 로드
    fetch('/static/data/regions.json')
        .then(response => response.json())
        .then(data => {
            regionData = data;
            createRegionTree(cityBtnContainer, data);
            return fetch('/api/pothole-groups');
        })
        .then(response => response.json())
        .then(groups => {
            if (groups.length === 0) { console.log("표시할 포트홀 그룹 데이터가 없습니다."); return; }
            const bounds = new kakao.maps.LatLngBounds();
            const groupListEl = document.getElementById('group-list');
            groupListEl.innerHTML = '';

            groups.forEach(group => {
                const markerPosition = new kakao.maps.LatLng(group.latitude, group.longitude);
                bounds.extend(markerPosition);
                const groupColors = getGroupColorById(group.group_id);
                const statusColor = getStatusColor(group.status);
                const regionName = getRegionFromCoords(group.latitude, group.longitude);
                const regionColor = getRegionColor(regionName);

                const svgMarker = `<svg xmlns="http://www.w3.org/2000/svg" width="30" height="40" viewBox="0 0 30 40"><path fill="${groupColors.stroke}" d="M15 0C6.7 0 0 6.7 0 15c0 11 15 25 15 25s15-14 15-25c0-8.3-6.7-15-15-15zm0 20c-2.8 0-5-2.2-5-5s2.2-5 5-5 5 2.2 5 5-2.2 5-5 5z"/></svg>`;
                const markerImage = new kakao.maps.MarkerImage('data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svgMarker), new kakao.maps.Size(30, 40), { offset: new kakao.maps.Point(15, 40) });
                const marker = new kakao.maps.Marker({ position: markerPosition, map: map, image: markerImage });

                const circle = new kakao.maps.Circle({ center : markerPosition, radius: 10, strokeWeight: 1, strokeColor: groupColors.stroke, strokeOpacity: 0.8, strokeStyle: 'solid', fillColor: groupColors.fill, fillOpacity: 0.5 });
                circle.setMap(map);

                const contentEl = document.createElement('div');
                contentEl.className = 'infowindow-content';
                contentEl.innerHTML = `<div style="font-weight:bold; margin-bottom:5px; color:#333;">🚧 포트홀 그룹</div><div style="font-size:0.9em; margin-bottom:3px;"><span style="color:#666;">그룹 ID:</span> ${group.group_id}</div><div style="font-size:0.9em; margin-bottom:3px;"><span style="color:#666;">상태:</span> <span class="badge" style="background-color:${statusColor}">${group.status}</span></div><div style="font-size:0.9em; margin-bottom:3px;"><span style="color:#666;">신고 건수:</span> <span class="badge bg-danger">${group.report_count}건</span></div><div style="font-size:0.9em; background:#f8f9fa; padding:5px; border-radius:4px; margin-top:5px;"><div style="color:#666; font-size:0.8em;">포함된 신고 ID:</div><div style="font-family:monospace; word-break:break-all;">[ ${group.report_ids.join(', ')} ]</div></div>`;
                const infowindow = new kakao.maps.InfoWindow({ content: contentEl, removable: true });

                const listItem = document.createElement('a');
                listItem.className = 'list-group-item list-group-item-action';
                listItem.innerHTML = `<div class="d-flex w-100 justify-content-between"><small class="text-muted" style="font-size: 0.75rem;">${group.group_id.substring(0, 8)}...</small><span class="badge" style="background-color:${statusColor}">${group.status}</span></div><div class="mb-1 mt-1 fw-bold" style="font-size: 0.9rem;">신고 ${group.report_count}건</div><div class="mb-1" style="font-size: 0.8rem; color: ${regionColor}; font-weight: 600;">📍 ${regionName || '위치 정보 없음'}</div><small class="text-muted">${new Date(group.latest_reported_at).toLocaleString()}</small>`;
                listItem.onclick = function() {
                    if (listItem.classList.contains('active')) {
                        listItem.classList.remove('active');
                        if (activeInfoWindow) { activeInfoWindow.close(); activeInfoWindow = null; }
                    } else {
                        if (map.getLevel() > 3) { map.setLevel(3, {animate: true}); }
                        map.panTo(markerPosition);
                        if (activeInfoWindow) activeInfoWindow.close();
                        infowindow.open(map, marker);
                        activeInfoWindow = infowindow;
                        document.querySelectorAll('#group-list .list-group-item').forEach(el => el.classList.remove('active'));
                        listItem.classList.add('active');
                    }
                };
                groupListEl.appendChild(listItem);

                kakao.maps.event.addListener(marker, 'click', function() {
                    if (activeInfoWindow) { activeInfoWindow.close(); }
                    infowindow.open(map, marker);
                    activeInfoWindow = infowindow;
                    document.querySelectorAll('#group-list .list-group-item').forEach(el => el.classList.remove('active'));
                    listItem.classList.add('active');
                    listItem.scrollIntoView({ behavior: 'smooth', block: 'center' });
                });
            });
            map.setBounds(bounds);
        })
        .catch(error => console.error('Error loading data:', error));
});