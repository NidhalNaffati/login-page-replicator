import { useAuth } from "@/contexts/AuthContext";
import { useNavigate } from "react-router-dom";
import { Search, HelpCircle, Power, Menu, FolderOpen, ChevronDown, ArrowRight, CheckCircle, Briefcase, Users, Heart, HelpCircle as HelpIcon } from "lucide-react";
import { Input } from "@/components/ui/input";

const Dashboard = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  if (!user) {
    navigate("/");
    return null;
  }

  return (
    <div className="min-h-screen bg-[hsl(0,0%,96%)]">
      {/* Top Navbar */}
      <header className="bg-[hsl(0,0%,20%)] h-12 flex items-center justify-between px-4 text-white">
        <div className="flex items-center gap-3">
          <button className="hover:opacity-80"><Menu className="h-5 w-5" /></button>
          <div className="flex items-center justify-center w-9 h-9">
            <div className="w-9 h-9 rounded-full border-2 border-[hsl(270,70%,50%)] flex items-center justify-center">
              <span className="text-[10px] font-bold leading-none">4<br/>YOU</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-5">
          <button className="hover:opacity-80"><Search className="h-5 w-5" /></button>
          <button className="hover:opacity-80"><HelpCircle className="h-5 w-5" /></button>
          <button onClick={handleLogout} className="hover:opacity-80"><Power className="h-5 w-5" /></button>
        </div>
      </header>

      {/* Hero Banner + User Info */}
      <div className="flex" style={{ height: "280px" }}>
        {/* Banner Image Area */}
        <div
          className="flex-1 relative overflow-hidden"
          style={{
            background: "linear-gradient(135deg, hsl(260 40% 15%) 0%, hsl(270 50% 25%) 30%, hsl(280 40% 35%) 50%, hsl(300 30% 30%) 70%, hsl(260 30% 20%) 100%)",
          }}
        >
          {/* Abstract colored overlay */}
          <div className="absolute inset-0" style={{
            background: "radial-gradient(ellipse at 40% 60%, hsl(280 60% 40% / 0.6) 0%, transparent 60%), radial-gradient(ellipse at 70% 30%, hsl(200 60% 30% / 0.4) 0%, transparent 50%), radial-gradient(ellipse at 20% 40%, hsl(320 50% 35% / 0.5) 0%, transparent 50%)"
          }} />
        </div>

        {/* User Info Panel */}
        <div className="w-[320px] bg-[hsl(0,0%,20%)] flex flex-col items-center justify-center gap-3 relative">
          <div className="w-24 h-24 rounded-full border-[3px] border-[hsl(270,60%,50%)] bg-[hsl(0,0%,75%)] flex items-center justify-center overflow-hidden">
            <span className="text-4xl text-[hsl(0,0%,50%)]">👤</span>
          </div>
          <h2 className="text-white font-medium text-base tracking-wide">
            {user.id.toUpperCase()} {user.name.toUpperCase()}
          </h2>
          <div className="flex items-center gap-1.5 text-white text-sm">
            <span>{user.folderCount}</span>
            <FolderOpen className="h-4 w-4" />
          </div>
          {/* Arrow button */}
          <button className="absolute right-3 bottom-1/3 w-10 h-10 rounded-full border-2 border-white/70 flex items-center justify-center text-white hover:bg-white/10">
            <ArrowRight className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Content Area */}
      <div className="flex gap-0 px-2 -mt-2 relative z-10">
        {/* Left Section - Cards */}
        <div className="flex-1 flex gap-3 pr-3">
          {/* Tasks Card */}
          <div className="bg-[hsl(195,50%,95%)] rounded p-6 flex-1 flex items-center justify-center min-h-[120px]">
            <p className="text-[hsl(195,60%,40%)] text-sm text-center">
              Vous n'avez actuellement aucune tâche à traiter.
            </p>
          </div>

          {/* Congés Card */}
          <div className="bg-[hsl(260,50%,25%)] rounded p-5 text-white text-center min-w-[180px] min-h-[120px] flex flex-col justify-center">
            <p className="text-sm mb-2 font-light italic">Mon solde de congés</p>
            <div className="text-3xl font-bold">18<span className="text-base font-normal ml-0.5">j</span></div>
            <div className="border-t border-white/30 my-2 mx-4" />
            <div className="text-xl font-bold">18<span className="text-base font-normal ml-0.5">j</span></div>
          </div>

          {/* Absences Card */}
          <div className="bg-[hsl(260,50%,25%)] rounded p-5 text-white text-center min-w-[180px] min-h-[120px] flex flex-col justify-center">
            <p className="text-sm mb-2 font-light italic">Mes autres absences</p>
            <div className="text-3xl font-bold">0<span className="text-base font-normal ml-0.5">j pris</span></div>
          </div>
        </div>

        {/* Right Sidebar - Démarches */}
        <div className="w-[360px] bg-white rounded shadow-sm p-4">
          <Input
            placeholder="Rechercher"
            className="mb-4 border-[hsl(0,0%,80%)] rounded-sm"
          />

          <div className="space-y-5">
            <DemarcheItem
              icon={<Briefcase className="h-5 w-5 text-white" />}
              title="Ma demande d'acompte ou d'avance"
              validated={5}
              refused={4}
            />
            <DemarcheItem
              icon={<Users className="h-5 w-5 text-white" />}
              title="Mon changement de composition familiale"
              validated={8}
              refused={2}
            />
            <DemarcheItem
              icon={<Heart className="h-5 w-5 text-white" />}
              title="Mon changement de situation familiale"
              validated={1}
            />
            <DemarcheItem
              icon={<HelpIcon className="h-5 w-5 text-white" />}
              title="Mes questions RH"
            />
          </div>

          <div className="mt-4 border-t border-[hsl(0,0%,90%)] pt-3 flex items-center justify-end gap-1 text-[hsl(210,80%,45%)] text-sm cursor-pointer hover:underline">
            <CheckCircle className="h-4 w-4" />
            Accéder à toutes mes démarches
          </div>

          <div className="flex justify-center mt-2">
            <ChevronDown className="h-5 w-5 text-[hsl(0,0%,60%)]" />
          </div>
        </div>
      </div>
    </div>
  );
};

const DemarcheItem = ({
  icon,
  title,
  validated,
  refused,
}: {
  icon: React.ReactNode;
  title: string;
  validated?: number;
  refused?: number;
}) => (
  <div className="flex items-center gap-3">
    <div className="w-11 h-11 rounded-full bg-[hsl(260,40%,30%)] flex items-center justify-center border-2 border-[hsl(270,50%,45%)] shrink-0">
      {icon}
    </div>
    <div>
      <p className="text-sm font-medium text-[hsl(0,0%,15%)]">{title}</p>
      {(validated !== undefined || refused !== undefined) && (
        <p className="text-xs mt-0.5">
          {validated !== undefined && <span className="text-[hsl(150,60%,35%)]">{validated} validée{validated > 1 ? "s" : ""}</span>}
          {validated !== undefined && refused !== undefined && <span className="text-[hsl(0,0%,60%)]"> | </span>}
          {refused !== undefined && <span className="text-[hsl(0,70%,50%)]">{refused} refusée{refused > 1 ? "s" : ""}</span>}
        </p>
      )}
    </div>
  </div>
);

export default Dashboard;
