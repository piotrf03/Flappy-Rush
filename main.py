import pygame
import random
import math

# --- Inicjalizacja Pygame ---
pygame.init()

# --- Stałe i ustawienia ---
WIDTH, HEIGHT = 800, 600
FPS = 60

# Kolory
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 50, 50)
GREEN = (50, 200, 50)
DARK_GREEN = (30, 150, 30)
SKY_BLUE = (135, 206, 235)
YELLOW = (255, 215, 0)
GROUND_COLOR = (139, 69, 19)

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Physics Sling Scroller")
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 48)
small_font = pygame.font.SysFont(None, 24)

# --- Klasy ---
class Player:
    def __init__(self):
        self.radius = 15
        self.x = WIDTH // 4
        self.y = HEIGHT // 2
        self.vx = 0
        self.vy = 0
        self.gravity = 0.5
        self.rect = pygame.Rect(self.x - self.radius, self.y - self.radius, self.radius*2, self.radius*2)
        self.is_grounded = False
        self.is_resting = False

    def update(self, static_obstacles, lethal_obstacles, scroll_speed):
        # 1. Fizyka bazowa
        self.vy += self.gravity
        if self.is_grounded:
            self.vx *= 0.7 
            self.x -= scroll_speed # Ziemia/rura przesuwa postać w lewo
        else:
            self.vx *= 0.99

        if abs(self.vx) < 0.1: self.vx = 0

        # 2. Śmiertelne Kolizje (Spadające bloki)
        for lethal in lethal_obstacles:
            if self.rect.colliderect(lethal):
                return False # Koniec gry!

        # 3. RUCH I KOLIZJE W OSI X (Pancerna fizyka - zapobieganie teleportacji)
        old_right = self.rect.right - self.vx
        old_left = self.rect.left - self.vx
        
        self.x += self.vx
        self.rect.centerx = int(self.x)
        
        for obs in static_obstacles:
            if self.rect.colliderect(obs):
                # Gdzie była przeszkoda w poprzedniej klatce? 
                # (Dodajemy scroll_speed, bo w tej klatce przeszkoda już się przesunęła w lewo)
                old_obs_left = obs.left + scroll_speed
                old_obs_right = obs.right + scroll_speed
                
                # Uderzyliśmy/zostaliśmy najechani z LEWEJ strony
                if old_right <= old_obs_left + 1: # +1 margines błędu zaokrągleń
                    self.rect.right = obs.left
                    self.vx = -abs(self.vx) * 0.5 # Wymuś odbicie w lewo
                # Uderzyliśmy z PRAWEJ strony
                elif old_left >= old_obs_right - 1:
                    self.rect.left = obs.right
                    self.vx = abs(self.vx) * 0.5 # Wymuś odbicie w prawo
                else:
                    # Ostateczny ratunek w przypadku idealnego rogu (MTV)
                    dist_left = self.rect.right - obs.left
                    dist_right = obs.right - self.rect.left
                    if dist_left < dist_right:
                        self.rect.right = obs.left
                        self.vx = -abs(self.vx) * 0.5
                    else:
                        self.rect.left = obs.right
                        self.vx = abs(self.vx) * 0.5
                        
                self.x = self.rect.centerx

        # 4. RUCH I KOLIZJE W OSI Y
        old_bottom = self.rect.bottom - self.vy
        old_top = self.rect.top - self.vy
        
        self.y += self.vy
        self.rect.centery = int(self.y)
        self.is_grounded = False
        
        for obs in static_obstacles:
            if self.rect.colliderect(obs):
                if old_bottom <= obs.top + 1: # Lądowanie
                    self.rect.bottom = obs.top
                    self.vy = 0
                    self.is_grounded = True
                elif old_top >= obs.bottom - 1: # Sufit
                    self.rect.top = obs.bottom
                    self.vy = -self.vy * 0.4
                else:
                    dist_top = self.rect.bottom - obs.top
                    dist_bottom = obs.bottom - self.rect.top
                    if dist_top < dist_bottom:
                        self.rect.bottom = obs.top
                        self.vy = 0
                        self.is_grounded = True
                    else:
                        self.rect.top = obs.bottom
                        self.vy = -self.vy * 0.4
                        
                self.y = self.rect.centery

        # 5. Stabilizacja lądowania na podłożu
        self.rect.y += 1
        for obs in static_obstacles:
            if self.rect.colliderect(obs):
                self.is_grounded = True
                break
        self.rect.y -= 1

        self.is_resting = self.is_grounded and math.hypot(self.vx, self.vy) < 1.0

        # 6. WARUNKI PRZEGRANEJ (Za ekranem)
        if (self.rect.right < 0 or self.rect.left > WIDTH or 
            self.rect.top > HEIGHT or self.rect.bottom < 0):
            return False
            
        return True

    def draw(self):
        color = GREEN if self.is_resting else YELLOW
        pygame.draw.circle(screen, color, (int(self.x), int(self.y)), self.radius)
        pygame.draw.circle(screen, BLACK, (int(self.x + 5), int(self.y - 5)), 3)

class Pipe:
    def __init__(self, x):
        self.x = x
        self.width = 100
        self.gap = 180
        self.gap_y = random.randint(100, HEIGHT - 150 - self.gap)
        self.passed = False
        self.top_rect = pygame.Rect(self.x, 0, self.width, self.gap_y)
        self.bottom_rect = pygame.Rect(self.x, self.gap_y + self.gap, self.width, HEIGHT - self.gap_y - self.gap)

    def update(self, scroll_speed):
        self.x -= scroll_speed
        self.top_rect.x = int(self.x)
        self.bottom_rect.x = int(self.x)

    def draw(self):
        pygame.draw.rect(screen, DARK_GREEN, self.top_rect)
        pygame.draw.rect(screen, DARK_GREEN, self.bottom_rect)

class FallingBlock:
    def __init__(self, x, speed):
        self.rect = pygame.Rect(x, -50, 40, 40)
        self.speed = speed

    def update(self, scroll_speed):
        self.rect.y += self.speed
        self.rect.x -= scroll_speed

    def draw(self):
        pygame.draw.rect(screen, RED, self.rect)
        pygame.draw.rect(screen, BLACK, self.rect, 3)

class StreamManager:
    def __init__(self):
        self.blocks = []
        self.spawn_timer = 0
        self.gap_timer = 0
        self.is_gap_active = False
        
        self.spawn_rate = 14         # Co 14 klatek leci klocek (tworzy gęsty strumień)
        self.blocks_before_gap = 10  # Po 10 klockach robimy przerwę
        self.gap_duration = 35       # Okno czasowe do przelotu
        
        self.current_series_count = 0
        self.current_stream_x = None

    def start_new_stream(self, x):
        self.current_stream_x = x
        self.current_series_count = 0
        self.is_gap_active = False
        self.spawn_timer = 0

    def update(self, scroll_speed):
        if self.current_stream_x is not None:
            self.current_stream_x -= scroll_speed
            self.spawn_timer += 1
            
            if self.current_series_count >= self.blocks_before_gap:
                self.is_gap_active = True
                self.gap_timer += 1
                if self.gap_timer >= self.gap_duration:
                    self.is_gap_active = False
                    self.gap_timer = 0
                    self.current_series_count = 0
                    
            if self.spawn_timer >= self.spawn_rate:
                self.spawn_timer = 0
                if not self.is_gap_active:
                    self.blocks.append(FallingBlock(self.current_stream_x, 5.5))
                    self.current_series_count += 1
                    
        for b in self.blocks[:]:
            b.update(scroll_speed)
            if b.rect.y > HEIGHT or b.rect.right < 0: self.blocks.remove(b)

    def draw(self):
        for b in self.blocks:
            b.draw()

# --- Główna Pętla Gry ---
def main():
    player = Player()
    pipes = []
    stream_manager = StreamManager()
    floor_rect = pygame.Rect(0, HEIGHT - 30, WIDTH, 30)
    
    scroll_speed = 3.0
    score = 0
    dragging = False
    drag_start = (0, 0)

    for i in range(2): 
        pipes.append(Pipe(WIDTH + i * 500))

    running = True
    game_over = False
    
    while running:
        clock.tick(FPS)
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT: 
                running = False
            if not game_over:
                if event.type == pygame.MOUSEBUTTONDOWN and player.is_resting:
                    dragging = True
                    drag_start = pygame.mouse.get_pos()
                elif event.type == pygame.MOUSEBUTTONUP and dragging:
                    dragging = False
                    drag_end = pygame.mouse.get_pos()
                    dx, dy = drag_start[0] - drag_end[0], drag_start[1] - drag_end[1]
                    dist = math.hypot(dx, dy)
                    if dist > 150: 
                        dx, dy = dx*150/dist, dy*150/dist
                    player.vx, player.vy = dx*0.15, dy*0.15
                    player.is_grounded = False
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                return main()

        if not game_over:
            scroll_speed += 0.0005
            
            for p in pipes: 
                p.update(scroll_speed)
                
            stream_manager.update(scroll_speed)
            
            if pipes[-1].x < WIDTH - 450:
                pipes.append(Pipe(WIDTH + 50))
                # 65% szans na ścianę spadających bloków
                if random.random() < 0.65: 
                    stream_manager.start_new_stream(WIDTH + 275)

            # Podział na obiekty do odbijania (static) i do przegrywania (lethal)
            static = [floor_rect]
            for p in pipes: 
                static.extend([p.top_rect, p.bottom_rect])
                
            lethal = [b.rect for b in stream_manager.blocks]

            if not player.update(static, lethal, scroll_speed): 
                game_over = True
                
            if dragging and not player.is_resting: 
                dragging = False

            # Punkty
            for p in pipes[:]:
                if p.x + p.width < -100: 
                    pipes.remove(p)
                elif not p.passed and p.x < player.x:
                    p.passed = True
                    score += 1

        # Rysowanie
        screen.fill(SKY_BLUE)
        pygame.draw.rect(screen, GROUND_COLOR, floor_rect)
        
        for p in pipes: p.draw()
        stream_manager.draw()
        player.draw()

        # Rysowanie procy
        if dragging and not game_over:
            curr = pygame.mouse.get_pos()
            dx, dy = drag_start[0] - curr[0], drag_start[1] - curr[1]
            dist = math.hypot(dx, dy)
            if dist > 150: 
                dx, dy = dx*150/dist, dy*150/dist
            pygame.draw.line(screen, WHITE, (player.x, player.y), (player.x - dx, player.y - dy), 2)
            pygame.draw.line(screen, RED, (player.x, player.y), (player.x + dx, player.y + dy), 4)

        # UI
        screen.blit(font.render(f"Score: {score}", True, BLACK), (20, 20))
        
        if game_over:
            overlay = pygame.Surface((WIDTH, HEIGHT))
            overlay.set_alpha(150)
            overlay.fill(BLACK)
            screen.blit(overlay, (0,0))
            
            go_text = font.render("GAME OVER! SPACE = RESTART", True, RED)
            screen.blit(go_text, (WIDTH//2 - go_text.get_width()//2, HEIGHT//2))
            
        pygame.display.flip()
        
    pygame.quit()

if __name__ == "__main__": 
    main()